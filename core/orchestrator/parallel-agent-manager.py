#!/usr/bin/env python3
"""
Parallel Agent Manager - Concurrent Task Execution System
Enterprise-grade async processing for Exxede Agent System
"""

import asyncio
import aiohttp
import json
import time
import uuid
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Callable, Tuple, Union
from dataclasses import dataclass, field
from enum import Enum
import concurrent.futures
from pathlib import Path
import logging
from contextlib import asynccontextmanager
import threading
import queue
from collections import defaultdict

from multi_model_orchestrator import MultiModelOrchestrator, ClaudeModel, AgentCapability, TaskComplexity

class TaskStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"  
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

class PriorityLevel(Enum):
    LOW = 1
    NORMAL = 2
    HIGH = 3
    CRITICAL = 4

@dataclass
class AgentTask:
    task_id: str
    agent_id: str
    description: str
    model: ClaudeModel
    priority: PriorityLevel = PriorityLevel.NORMAL
    dependencies: List[str] = field(default_factory=list)
    context: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    status: TaskStatus = TaskStatus.PENDING
    result: Optional[Any] = None
    error: Optional[Exception] = None
    execution_time: float = 0.0
    token_usage: Dict[str, int] = field(default_factory=dict)
    cost: float = 0.0
    retries: int = 0
    max_retries: int = 3

@dataclass
class ParallelExecutionResult:
    session_id: str
    total_tasks: int
    completed_tasks: int
    failed_tasks: int
    cancelled_tasks: int
    total_execution_time: float
    total_cost: float
    total_tokens: Dict[str, int]
    agent_performance: Dict[str, Any]
    task_results: Dict[str, Any]
    bottlenecks: List[str]
    optimization_suggestions: List[str]

class SharedContextManager:
    """Manages shared context between agents for communication."""
    
    def __init__(self):
        self._context_store = {}
        self._context_lock = threading.RLock()
        self._subscribers = defaultdict(list)
        
    def set_context(self, key: str, value: Any, agent_id: str = None) -> None:
        """Set shared context value."""
        with self._context_lock:
            self._context_store[key] = {
                "value": value,
                "agent_id": agent_id,
                "timestamp": datetime.now(),
                "access_count": 0
            }
            # Notify subscribers
            for callback in self._subscribers[key]:
                try:
                    callback(key, value, agent_id)
                except Exception as e:
                    logging.warning(f"Context subscriber error: {e}")
    
    def get_context(self, key: str, default=None) -> Any:
        """Get shared context value."""
        with self._context_lock:
            if key in self._context_store:
                self._context_store[key]["access_count"] += 1
                return self._context_store[key]["value"]
            return default
    
    def subscribe(self, key: str, callback: Callable) -> None:
        """Subscribe to context changes."""
        self._subscribers[key].append(callback)
    
    def get_all_context(self) -> Dict[str, Any]:
        """Get all context for debugging."""
        with self._context_lock:
            return {k: v["value"] for k, v in self._context_store.items()}

class TaskQueue:
    """Priority-based task queue with dependency resolution."""
    
    def __init__(self):
        self._queue = queue.PriorityQueue()
        self._task_map = {}
        self._dependency_graph = defaultdict(set)
        self._reverse_deps = defaultdict(set)
        self._lock = threading.Lock()
    
    def add_task(self, task: AgentTask) -> None:
        """Add task to queue with priority and dependency handling."""
        with self._lock:
            self._task_map[task.task_id] = task
            
            # Build dependency graph
            for dep_id in task.dependencies:
                self._dependency_graph[dep_id].add(task.task_id)
                self._reverse_deps[task.task_id].add(dep_id)
            
            # If no pending dependencies, add to queue
            if self._can_execute(task.task_id):
                priority_score = (task.priority.value, -time.time())
                self._queue.put((priority_score, task.task_id))
    
    def get_next_task(self, timeout=None) -> Optional[AgentTask]:
        """Get next executable task."""
        try:
            _, task_id = self._queue.get(timeout=timeout)
            with self._lock:
                if task_id in self._task_map:
                    return self._task_map[task_id]
            return None
        except queue.Empty:
            return None
    
    def complete_task(self, task_id: str) -> None:
        """Mark task as completed and release dependent tasks."""
        with self._lock:
            # Release dependent tasks
            for dependent_id in self._dependency_graph.get(task_id, set()):
                self._reverse_deps[dependent_id].discard(task_id)
                
                # If all dependencies resolved, add to queue
                if self._can_execute(dependent_id):
                    task = self._task_map[dependent_id]
                    priority_score = (task.priority.value, -time.time())
                    self._queue.put((priority_score, dependent_id))
    
    def _can_execute(self, task_id: str) -> bool:
        """Check if task can be executed (no pending dependencies)."""
        return len(self._reverse_deps[task_id]) == 0
    
    def get_queue_size(self) -> int:
        """Get current queue size."""
        return self._queue.qsize()
    
    def get_waiting_tasks(self) -> List[str]:
        """Get tasks waiting for dependencies."""
        with self._lock:
            return [tid for tid, deps in self._reverse_deps.items() if deps]

class ParallelAgentManager:
    """Enterprise-grade parallel agent execution manager."""
    
    def __init__(self, orchestrator: MultiModelOrchestrator = None, max_workers: int = 8):
        self.orchestrator = orchestrator or MultiModelOrchestrator()
        self.max_workers = max_workers
        self.task_queue = TaskQueue()
        self.shared_context = SharedContextManager()
        self.active_tasks = {}
        self.completed_tasks = {}
        self.performance_metrics = defaultdict(list)
        
        # Performance monitoring
        self.session_start_time = None
        self.total_cost = 0.0
        self.total_tokens = defaultdict(int)
        
        # Async resources
        self.session = None
        self.executor = None
        self._shutdown_event = threading.Event()
        
        # Logging setup
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
    
    async def __aenter__(self):
        """Async context manager entry."""
        await self.initialize()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        await self.shutdown()
    
    async def initialize(self) -> None:
        """Initialize async resources."""
        self.session = aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=300),  # 5 minute timeout
            connector=aiohttp.TCPConnector(limit=self.max_workers)
        )
        self.executor = concurrent.futures.ThreadPoolExecutor(
            max_workers=self.max_workers,
            thread_name_prefix="AgentWorker"
        )
        self.session_start_time = time.time()
        self.logger.info(f"Parallel Agent Manager initialized with {self.max_workers} workers")
    
    async def shutdown(self) -> None:
        """Cleanup resources."""
        self._shutdown_event.set()
        
        if self.session:
            await self.session.close()
        
        if self.executor:
            self.executor.shutdown(wait=True)
        
        self.logger.info("Parallel Agent Manager shutdown complete")
    
    def create_task(
        self,
        agent_id: str,
        description: str,
        priority: PriorityLevel = PriorityLevel.NORMAL,
        dependencies: List[str] = None,
        context: Dict[str, Any] = None
    ) -> AgentTask:
        """Create a new agent task."""
        task_id = str(uuid.uuid4())
        
        # Get optimal model for agent and task
        if agent_id in self.orchestrator.elite_agents:
            agent = self.orchestrator.elite_agents[agent_id]
            task_complexity = self.orchestrator.classify_task_complexity(description)
            model = agent.model_preferences[task_complexity]
        else:
            model = ClaudeModel.SONNET  # Default fallback
        
        task = AgentTask(
            task_id=task_id,
            agent_id=agent_id,
            description=description,
            model=model,
            priority=priority,
            dependencies=dependencies or [],
            context=context or {}
        )
        
        return task
    
    def submit_task(self, task: AgentTask) -> str:
        """Submit task for execution."""
        self.task_queue.add_task(task)
        self.logger.info(f"Task {task.task_id} submitted for agent {task.agent_id}")
        return task.task_id
    
    def submit_tasks(self, tasks: List[AgentTask]) -> List[str]:
        """Submit multiple tasks for execution."""
        task_ids = []
        for task in tasks:
            task_ids.append(self.submit_task(task))
        return task_ids
    
    async def execute_parallel_session(
        self,
        tasks: List[AgentTask],
        max_concurrent: int = None,
        timeout: float = 300.0
    ) -> ParallelExecutionResult:
        """Execute tasks in parallel with intelligent concurrency management."""
        max_concurrent = max_concurrent or self.max_workers
        session_id = str(uuid.uuid4())
        
        self.logger.info(f"Starting parallel session {session_id} with {len(tasks)} tasks")
        
        # Submit all tasks
        for task in tasks:
            self.task_queue.add_task(task)
        
        # Execute tasks with controlled concurrency
        semaphore = asyncio.Semaphore(max_concurrent)
        start_time = time.time()
        
        async def execute_single_task() -> Optional[AgentTask]:
            """Execute a single task from the queue."""
            async with semaphore:
                # Get next available task
                task = await asyncio.get_event_loop().run_in_executor(
                    self.executor, 
                    self.task_queue.get_next_task,
                    1.0  # 1 second timeout
                )
                
                if task is None:
                    return None
                
                return await self._execute_task(task)
        
        # Create worker coroutines
        workers = [
            asyncio.create_task(self._worker_loop(execute_single_task, timeout))
            for _ in range(max_concurrent)
        ]
        
        try:
            # Wait for all workers to complete or timeout
            await asyncio.wait_for(
                asyncio.gather(*workers, return_exceptions=True),
                timeout=timeout
            )
        except asyncio.TimeoutError:
            self.logger.warning(f"Session {session_id} timed out after {timeout}s")
            # Cancel remaining workers
            for worker in workers:
                worker.cancel()
        
        execution_time = time.time() - start_time
        
        # Generate results
        result = self._generate_execution_result(session_id, execution_time)
        
        self.logger.info(
            f"Session {session_id} completed: {result.completed_tasks}/{result.total_tasks} "
            f"tasks in {execution_time:.2f}s, cost: ${result.total_cost:.4f}"
        )
        
        return result
    
    async def _worker_loop(
        self,
        execute_func: Callable,
        timeout: float
    ) -> None:
        """Worker loop for processing tasks."""
        end_time = time.time() + timeout
        
        while time.time() < end_time and not self._shutdown_event.is_set():
            try:
                task = await execute_func()
                if task is None:
                    # No more tasks available, check if any are waiting
                    waiting_tasks = self.task_queue.get_waiting_tasks()
                    if not waiting_tasks and self.task_queue.get_queue_size() == 0:
                        break  # No more work to do
                    
                    # Wait a bit before checking again
                    await asyncio.sleep(0.1)
                    continue
                
                # Task completed, update queue
                self.task_queue.complete_task(task.task_id)
                
            except Exception as e:
                self.logger.error(f"Worker error: {e}")
                await asyncio.sleep(0.1)
    
    async def _execute_task(self, task: AgentTask) -> AgentTask:
        """Execute a single agent task."""
        task.status = TaskStatus.RUNNING
        task.started_at = datetime.now()
        self.active_tasks[task.task_id] = task
        
        start_time = time.time()
        
        try:
            self.logger.info(f"Executing task {task.task_id} for agent {task.agent_id}")
            
            # Prepare context for agent
            agent_context = {
                **task.context,
                "shared_context": self.shared_context.get_all_context(),
                "task_id": task.task_id,
                "agent_id": task.agent_id,
                "model": task.model.value["name"]
            }
            
            # Execute task (simulate API call for now)
            result = await self._simulate_agent_execution(task, agent_context)
            
            # Update task with results
            task.result = result
            task.status = TaskStatus.COMPLETED
            task.execution_time = time.time() - start_time
            
            # Update shared context with task results
            self.shared_context.set_context(
                f"task_{task.task_id}_result",
                result,
                task.agent_id
            )
            
            # Update performance metrics
            self._update_performance_metrics(task)
            
            self.logger.info(
                f"Task {task.task_id} completed in {task.execution_time:.2f}s, "
                f"cost: ${task.cost:.4f}"
            )
            
        except Exception as e:
            task.error = e
            task.status = TaskStatus.FAILED
            task.execution_time = time.time() - start_time
            
            self.logger.error(f"Task {task.task_id} failed: {e}")
            
            # Retry logic
            if task.retries < task.max_retries:
                task.retries += 1
                task.status = TaskStatus.PENDING
                self.task_queue.add_task(task)
                self.logger.info(f"Retrying task {task.task_id} (attempt {task.retries + 1})")
        
        finally:
            task.completed_at = datetime.now()
            self.completed_tasks[task.task_id] = task
            self.active_tasks.pop(task.task_id, None)
        
        return task
    
    async def _simulate_agent_execution(
        self,
        task: AgentTask,
        context: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Simulate agent execution (replace with actual API calls)."""
        # Simulate processing time based on task complexity
        complexity_delays = {
            TaskComplexity.SIMPLE: (0.5, 2.0),
            TaskComplexity.MODERATE: (1.0, 4.0),
            TaskComplexity.COMPLEX: (2.0, 8.0),
            TaskComplexity.FRONTIER: (4.0, 15.0)
        }
        
        task_complexity = self.orchestrator.classify_task_complexity(task.description)
        min_delay, max_delay = complexity_delays.get(task_complexity, (1.0, 4.0))
        
        import random
        delay = random.uniform(min_delay, max_delay)
        await asyncio.sleep(delay)
        
        # Simulate token usage and cost calculation
        estimated_tokens = self.orchestrator.estimate_token_usage(task.description, task.model)
        task.token_usage = estimated_tokens
        task.cost = self.orchestrator.calculate_cost_estimate(task.description, task.model)
        
        # Update totals
        self.total_cost += task.cost
        for key, value in estimated_tokens.items():
            self.total_tokens[key] += value
        
        # Generate simulated result
        result = {
            "agent_id": task.agent_id,
            "task_completed": True,
            "output": f"Agent {task.agent_id} completed: {task.description}",
            "model_used": task.model.value["name"],
            "execution_time": delay,
            "token_usage": estimated_tokens,
            "cost": task.cost,
            "timestamp": datetime.now().isoformat()
        }
        
        return result
    
    def _update_performance_metrics(self, task: AgentTask) -> None:
        """Update performance metrics for analysis."""
        metrics = {
            "execution_time": task.execution_time,
            "cost": task.cost,
            "token_usage": task.token_usage,
            "model": task.model.value["name"],
            "complexity": self.orchestrator.classify_task_complexity(task.description),
            "retries": task.retries,
            "timestamp": task.completed_at.isoformat()
        }
        
        self.performance_metrics[task.agent_id].append(metrics)
    
    def _generate_execution_result(
        self,
        session_id: str,
        execution_time: float
    ) -> ParallelExecutionResult:
        """Generate comprehensive execution results."""
        completed_tasks = len([t for t in self.completed_tasks.values() if t.status == TaskStatus.COMPLETED])
        failed_tasks = len([t for t in self.completed_tasks.values() if t.status == TaskStatus.FAILED])
        cancelled_tasks = len([t for t in self.completed_tasks.values() if t.status == TaskStatus.CANCELLED])
        
        # Analyze agent performance
        agent_performance = {}
        for agent_id, metrics in self.performance_metrics.items():
            if metrics:
                avg_time = sum(m["execution_time"] for m in metrics) / len(metrics)
                total_cost = sum(m["cost"] for m in metrics)
                total_tokens = sum(m["token_usage"]["total_tokens"] for m in metrics)
                
                agent_performance[agent_id] = {
                    "task_count": len(metrics),
                    "avg_execution_time": avg_time,
                    "total_cost": total_cost,
                    "total_tokens": total_tokens,
                    "success_rate": len([m for m in metrics if "error" not in m]) / len(metrics)
                }
        
        # Identify bottlenecks
        bottlenecks = self._identify_bottlenecks()
        
        # Generate optimization suggestions
        optimization_suggestions = self._generate_optimization_suggestions(agent_performance)
        
        return ParallelExecutionResult(
            session_id=session_id,
            total_tasks=len(self.completed_tasks),
            completed_tasks=completed_tasks,
            failed_tasks=failed_tasks,
            cancelled_tasks=cancelled_tasks,
            total_execution_time=execution_time,
            total_cost=self.total_cost,
            total_tokens=dict(self.total_tokens),
            agent_performance=agent_performance,
            task_results={tid: task.result for tid, task in self.completed_tasks.items()},
            bottlenecks=bottlenecks,
            optimization_suggestions=optimization_suggestions
        )
    
    def _identify_bottlenecks(self) -> List[str]:
        """Identify performance bottlenecks."""
        bottlenecks = []
        
        # Check for agents with high execution times
        for agent_id, metrics in self.performance_metrics.items():
            if metrics:
                avg_time = sum(m["execution_time"] for m in metrics) / len(metrics)
                if avg_time > 10.0:  # More than 10 seconds average
                    bottlenecks.append(f"Agent {agent_id} has high average execution time: {avg_time:.2f}s")
        
        # Check for high retry rates
        for agent_id, metrics in self.performance_metrics.items():
            if metrics:
                retry_rate = sum(m["retries"] for m in metrics) / len(metrics)
                if retry_rate > 0.5:
                    bottlenecks.append(f"Agent {agent_id} has high retry rate: {retry_rate:.1f}")
        
        return bottlenecks
    
    def _generate_optimization_suggestions(
        self,
        agent_performance: Dict[str, Any]
    ) -> List[str]:
        """Generate optimization suggestions based on performance data."""
        suggestions = []
        
        # Suggest model optimizations
        total_cost = sum(perf["total_cost"] for perf in agent_performance.values())
        if total_cost > 10.0:  # High cost threshold
            suggestions.append(
                "Consider using more Haiku models for simple tasks to reduce costs"
            )
        
        # Suggest concurrency optimizations
        if len(agent_performance) > self.max_workers:
            suggestions.append(
                f"Consider increasing max_workers from {self.max_workers} for better parallelization"
            )
        
        # Suggest caching for repeated tasks
        task_descriptions = [task.description for task in self.completed_tasks.values()]
        if len(task_descriptions) != len(set(task_descriptions)):
            suggestions.append(
                "Implement result caching for repeated tasks to improve efficiency"
            )
        
        return suggestions
    
    def get_session_status(self) -> Dict[str, Any]:
        """Get current session status."""
        return {
            "active_tasks": len(self.active_tasks),
            "completed_tasks": len(self.completed_tasks),
            "queue_size": self.task_queue.get_queue_size(),
            "waiting_tasks": len(self.task_queue.get_waiting_tasks()),
            "total_cost": self.total_cost,
            "total_tokens": dict(self.total_tokens),
            "uptime": time.time() - (self.session_start_time or time.time())
        }


# Convenience functions for easy usage
async def execute_parallel_agents(
    task_description: str,
    agents: List[str] = None,
    max_concurrent: int = 4,
    timeout: float = 300.0
) -> ParallelExecutionResult:
    """Execute multiple agents in parallel for a single task."""
    orchestrator = MultiModelOrchestrator()
    
    if not agents:
        agents = orchestrator.select_optimal_agents(task_description)
    
    async with ParallelAgentManager(orchestrator, max_concurrent) as manager:
        # Create tasks for each agent
        tasks = []
        for agent_id in agents:
            if agent_id in orchestrator.elite_agents:
                agent_task = orchestrator.determine_agent_task(agent_id, task_description)
                task = manager.create_task(
                    agent_id=agent_id,
                    description=agent_task,
                    priority=PriorityLevel.NORMAL
                )
                tasks.append(task)
        
        return await manager.execute_parallel_session(tasks, max_concurrent, timeout)


def create_agent_workflow(
    workflow_tasks: List[Dict[str, Any]],
    max_concurrent: int = 4
) -> List[AgentTask]:
    """Create a workflow of dependent agent tasks."""
    orchestrator = MultiModelOrchestrator()
    manager = ParallelAgentManager(orchestrator, max_concurrent)
    
    tasks = []
    for task_config in workflow_tasks:
        task = manager.create_task(
            agent_id=task_config["agent_id"],
            description=task_config["description"],
            priority=PriorityLevel(task_config.get("priority", 2)),
            dependencies=task_config.get("dependencies", []),
            context=task_config.get("context", {})
        )
        tasks.append(task)
    
    return tasks


if __name__ == "__main__":
    async def main():
        """Demo of parallel agent execution."""
        print("🚀 Parallel Agent Manager Demo")
        
        # Execute parallel agents for a complex task
        result = await execute_parallel_agents(
            "Design a fintech application for Dominican Republic market with scalable architecture",
            agents=["ARQ", "SAGE", "VEX", "ZEN", "NOVA"],
            max_concurrent=3,
            timeout=60.0
        )
        
        print(f"\n📊 Execution Results:")
        print(f"Tasks: {result.completed_tasks}/{result.total_tasks} completed")
        print(f"Time: {result.total_execution_time:.2f}s")
        print(f"Cost: ${result.total_cost:.4f}")
        print(f"Tokens: {result.total_tokens}")
        
        print(f"\n🔧 Agent Performance:")
        for agent_id, perf in result.agent_performance.items():
            print(f"  {agent_id}: {perf['task_count']} tasks, ${perf['total_cost']:.4f}")
        
        if result.optimization_suggestions:
            print(f"\n💡 Optimization Suggestions:")
            for suggestion in result.optimization_suggestions:
                print(f"  • {suggestion}")
    
    asyncio.run(main())