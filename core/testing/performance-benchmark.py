#!/usr/bin/env python3
"""
Performance Benchmark Suite for Exxede Agent System
Comprehensive testing of parallel vs sequential execution with detailed analytics
"""

import asyncio
import time
import statistics
import json
import csv
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field, asdict
from enum import Enum
from pathlib import Path
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
import psutil
import logging
import yaml

# Import our systems
import sys
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

try:
    from core.orchestrator.multi_model_orchestrator import MultiModelOrchestrator
    from core.orchestrator.parallel_agent_manager import ParallelAgentManager, PriorityLevel
    from core.orchestrator.async_multi_model_orchestrator import AsyncMultiModelOrchestrator, execute_async_agents
    from core.monitoring.performance_monitor import PerformanceMonitor, create_performance_monitor
except ImportError as e:
    print(f"❌ Error importing core modules: {e}")
    sys.exit(1)

class ExecutionMode(Enum):
    SEQUENTIAL = "sequential"
    PARALLEL = "parallel"
    ASYNC = "async"
    THREAD_POOL = "thread_pool"
    PROCESS_POOL = "process_pool"

class BenchmarkType(Enum):
    THROUGHPUT = "throughput"
    LATENCY = "latency"
    SCALABILITY = "scalability"
    COST_EFFICIENCY = "cost_efficiency"
    RESOURCE_USAGE = "resource_usage"

@dataclass
class BenchmarkConfig:
    name: str
    description: str
    task_description: str
    agents: List[str]
    execution_modes: List[ExecutionMode]
    iterations: int = 10
    max_concurrent: int = 8
    timeout: float = 300.0
    warm_up_iterations: int = 3
    enable_monitoring: bool = True
    collect_system_metrics: bool = True

@dataclass
class ExecutionResult:
    mode: ExecutionMode
    execution_time: float
    total_cost: float
    successful_tasks: int
    failed_tasks: int
    cpu_usage_avg: float
    memory_usage_avg: float
    throughput: float  # tasks per second
    latency_p50: float
    latency_p95: float
    latency_p99: float
    system_metrics: Dict[str, float] = field(default_factory=dict)
    agent_metrics: Dict[str, Any] = field(default_factory=dict)
    error_details: List[str] = field(default_factory=list)

@dataclass
class BenchmarkReport:
    config: BenchmarkConfig
    results: Dict[ExecutionMode, List[ExecutionResult]]
    summary: Dict[str, Any]
    comparisons: Dict[str, Dict[str, float]]
    recommendations: List[str]
    generated_at: datetime = field(default_factory=datetime.now)

class PerformanceBenchmark:
    """Comprehensive performance benchmarking system."""
    
    def __init__(self, output_dir: Path = None):
        self.output_dir = output_dir or Path.cwd() / "benchmark_results"
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize components
        self.orchestrator = MultiModelOrchestrator()
        self.parallel_manager = None
        self.async_orchestrator = None
        self.performance_monitor = None
        
        # Benchmark configurations
        self.benchmark_configs = self.create_default_benchmarks()
        
        # Results storage
        self.results = {}
        
        # Setup logging
        self.setup_logging()
        
    def setup_logging(self):
        """Setup logging for benchmarks."""
        log_file = self.output_dir / "benchmark.log"
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def create_default_benchmarks(self) -> List[BenchmarkConfig]:
        """Create default benchmark configurations."""
        return [
            BenchmarkConfig(
                name="small_task_benchmark",
                description="Small tasks with minimal complexity",
                task_description="Create a simple product description for a Caribbean resort",
                agents=["ECHO", "VEX"],
                execution_modes=[ExecutionMode.SEQUENTIAL, ExecutionMode.PARALLEL, ExecutionMode.ASYNC],
                iterations=20,
                max_concurrent=4
            ),
            BenchmarkConfig(
                name="medium_task_benchmark",
                description="Medium complexity tasks requiring analysis",
                task_description="Design a mobile app architecture for Dominican Republic tourism market",
                agents=["ARQ", "VEX", "SAGE", "ECHO"],
                execution_modes=[ExecutionMode.SEQUENTIAL, ExecutionMode.PARALLEL, ExecutionMode.ASYNC],
                iterations=10,
                max_concurrent=6
            ),
            BenchmarkConfig(
                name="large_task_benchmark",
                description="Complex tasks with multiple agents",
                task_description="Create comprehensive business strategy for fintech startup in Caribbean market",
                agents=["ARQ", "SAGE", "VEX", "NOVA", "ECHO", "ZEN"],
                execution_modes=[ExecutionMode.SEQUENTIAL, ExecutionMode.PARALLEL, ExecutionMode.ASYNC],
                iterations=5,
                max_concurrent=8
            ),
            BenchmarkConfig(
                name="scalability_benchmark",
                description="Test scalability with increasing agent count",
                task_description="Develop complete e-commerce platform strategy",
                agents=["ARQ", "SAGE", "VEX", "NOVA", "ECHO", "ZEN", "ORC", "APEX"],
                execution_modes=[ExecutionMode.PARALLEL, ExecutionMode.ASYNC],
                iterations=3,
                max_concurrent=10
            ),
            BenchmarkConfig(
                name="cost_efficiency_benchmark",
                description="Compare cost efficiency across execution modes",
                task_description="Market analysis for Dominican Republic real estate",
                agents=["SAGE", "ARQ", "ECHO"],
                execution_modes=[ExecutionMode.SEQUENTIAL, ExecutionMode.PARALLEL, ExecutionMode.ASYNC],
                iterations=15,
                max_concurrent=4
            )
        ]
    
    async def run_all_benchmarks(self) -> Dict[str, BenchmarkReport]:
        """Run all configured benchmarks."""
        self.logger.info("🚀 Starting comprehensive performance benchmarks")
        
        # Initialize performance monitor
        if not self.performance_monitor:
            self.performance_monitor = await create_performance_monitor(
                data_dir=self.output_dir / "monitoring"
            )
            await self.performance_monitor.start_monitoring()
        
        reports = {}
        
        try:
            for config in self.benchmark_configs:
                self.logger.info(f"📊 Running benchmark: {config.name}")
                report = await self.run_benchmark(config)
                reports[config.name] = report
                
                # Save individual report
                await self.save_report(report, config.name)
                
                # Brief pause between benchmarks
                await asyncio.sleep(5)
            
            # Generate comprehensive comparison report
            comparison_report = await self.generate_comparison_report(reports)
            await self.save_comparison_report(comparison_report)
            
        finally:
            if self.performance_monitor:
                await self.performance_monitor.stop_monitoring()
        
        self.logger.info("✅ All benchmarks completed")
        return reports
    
    async def run_benchmark(self, config: BenchmarkConfig) -> BenchmarkReport:
        """Run a specific benchmark configuration."""
        self.logger.info(f"🎯 Starting benchmark: {config.name}")
        self.logger.info(f"📝 Description: {config.description}")
        self.logger.info(f"🤖 Agents: {', '.join(config.agents)}")
        self.logger.info(f"🔄 Modes: {', '.join([mode.value for mode in config.execution_modes])}")
        
        results = {}
        
        for mode in config.execution_modes:
            self.logger.info(f"🚦 Testing {mode.value} execution...")
            
            mode_results = []
            
            # Warm-up iterations
            self.logger.info(f"🔥 Warming up with {config.warm_up_iterations} iterations...")
            for _ in range(config.warm_up_iterations):
                await self.execute_single_iteration(config, mode, is_warmup=True)
            
            # Actual benchmark iterations
            for iteration in range(config.iterations):
                self.logger.info(f"🔄 Iteration {iteration + 1}/{config.iterations}")
                
                result = await self.execute_single_iteration(config, mode)
                mode_results.append(result)
                
                # Brief pause between iterations
                await asyncio.sleep(1)
            
            results[mode] = mode_results
            
            # Calculate and log summary for this mode
            avg_time = statistics.mean([r.execution_time for r in mode_results])
            avg_cost = statistics.mean([r.total_cost for r in mode_results])
            success_rate = statistics.mean([r.successful_tasks / (r.successful_tasks + r.failed_tasks) for r in mode_results])
            
            self.logger.info(f"📈 {mode.value} summary: {avg_time:.2f}s avg, ${avg_cost:.4f} avg cost, {success_rate:.1%} success")
        
        # Generate benchmark report
        report = BenchmarkReport(
            config=config,
            results=results,
            summary=self.calculate_summary(results),
            comparisons=self.calculate_comparisons(results),
            recommendations=self.generate_recommendations(results)
        )
        
        return report
    
    async def execute_single_iteration(
        self, 
        config: BenchmarkConfig, 
        mode: ExecutionMode,
        is_warmup: bool = False
    ) -> Optional[ExecutionResult]:
        """Execute a single benchmark iteration."""
        
        if is_warmup:
            # Simplified warmup execution
            if mode == ExecutionMode.SEQUENTIAL:
                await self.execute_sequential(config.task_description, config.agents[:2])
            elif mode == ExecutionMode.PARALLEL:
                await self.execute_parallel(config.task_description, config.agents[:2], 2)
            elif mode == ExecutionMode.ASYNC:
                await self.execute_async(config.task_description, config.agents[:2], 2)
            return None
        
        # Track system metrics before execution
        initial_metrics = await self.get_system_metrics() if config.collect_system_metrics else {}
        
        start_time = time.time()
        cpu_usage_samples = []
        memory_usage_samples = []
        
        # Start monitoring task
        monitoring_task = None
        if config.collect_system_metrics:
            monitoring_task = asyncio.create_task(
                self.monitor_resources_during_execution(cpu_usage_samples, memory_usage_samples)
            )
        
        try:
            # Execute based on mode
            if mode == ExecutionMode.SEQUENTIAL:
                execution_result = await self.execute_sequential(config.task_description, config.agents)
            elif mode == ExecutionMode.PARALLEL:
                execution_result = await self.execute_parallel(
                    config.task_description, config.agents, config.max_concurrent
                )
            elif mode == ExecutionMode.ASYNC:
                execution_result = await self.execute_async(
                    config.task_description, config.agents, config.max_concurrent
                )
            elif mode == ExecutionMode.THREAD_POOL:
                execution_result = await self.execute_thread_pool(config.task_description, config.agents)
            elif mode == ExecutionMode.PROCESS_POOL:
                execution_result = await self.execute_process_pool(config.task_description, config.agents)
            else:
                raise ValueError(f"Unsupported execution mode: {mode}")
            
            execution_time = time.time() - start_time
            
            # Stop monitoring
            if monitoring_task:
                monitoring_task.cancel()
                try:
                    await monitoring_task
                except asyncio.CancelledError:
                    pass
            
            # Calculate metrics
            cpu_avg = statistics.mean(cpu_usage_samples) if cpu_usage_samples else 0
            memory_avg = statistics.mean(memory_usage_samples) if memory_usage_samples else 0
            
            # Extract results from execution
            successful_tasks = len([r for r in execution_result if r.get("error") is None])
            failed_tasks = len([r for r in execution_result if r.get("error") is not None])
            total_cost = sum([r.get("cost", 0) for r in execution_result])
            
            # Calculate latency metrics
            execution_times = [r.get("execution_time", 0) for r in execution_result if r.get("execution_time")]
            latency_p50 = statistics.median(execution_times) if execution_times else 0
            latency_p95 = np.percentile(execution_times, 95) if execution_times else 0
            latency_p99 = np.percentile(execution_times, 99) if execution_times else 0
            
            throughput = len(config.agents) / execution_time if execution_time > 0 else 0
            
            return ExecutionResult(
                mode=mode,
                execution_time=execution_time,
                total_cost=total_cost,
                successful_tasks=successful_tasks,
                failed_tasks=failed_tasks,
                cpu_usage_avg=cpu_avg,
                memory_usage_avg=memory_avg,
                throughput=throughput,
                latency_p50=latency_p50,
                latency_p95=latency_p95,
                latency_p99=latency_p99,
                system_metrics=await self.get_system_metrics() if config.collect_system_metrics else {},
                agent_metrics={},
                error_details=[r.get("error", "") for r in execution_result if r.get("error")]
            )
            
        except Exception as e:
            execution_time = time.time() - start_time
            
            if monitoring_task:
                monitoring_task.cancel()
            
            self.logger.error(f"Execution failed for {mode.value}: {e}")
            
            return ExecutionResult(
                mode=mode,
                execution_time=execution_time,
                total_cost=0,
                successful_tasks=0,
                failed_tasks=len(config.agents),
                cpu_usage_avg=0,
                memory_usage_avg=0,
                throughput=0,
                latency_p50=0,
                latency_p95=0,
                latency_p99=0,
                error_details=[str(e)]
            )
    
    async def execute_sequential(self, task_description: str, agents: List[str]) -> List[Dict[str, Any]]:
        """Execute agents sequentially."""
        results = []
        
        for agent_id in agents:
            if agent_id not in self.orchestrator.elite_agents:
                continue
            
            start_time = time.time()
            
            try:
                # Simulate agent execution
                agent_task = self.orchestrator.determine_agent_task(agent_id, task_description)
                agent = self.orchestrator.elite_agents[agent_id]
                task_complexity = self.orchestrator.classify_task_complexity(agent_task)
                model = agent.model_preferences[task_complexity]
                
                # Simulate execution time and cost
                await asyncio.sleep(0.5)  # Simulate processing
                
                execution_time = time.time() - start_time
                cost = self.orchestrator.calculate_cost_estimate(agent_task, model)
                
                results.append({
                    "agent_id": agent_id,
                    "execution_time": execution_time,
                    "cost": cost,
                    "success": True
                })
                
            except Exception as e:
                execution_time = time.time() - start_time
                results.append({
                    "agent_id": agent_id,
                    "execution_time": execution_time,
                    "cost": 0,
                    "success": False,
                    "error": str(e)
                })
        
        return results
    
    async def execute_parallel(
        self, 
        task_description: str, 
        agents: List[str], 
        max_concurrent: int
    ) -> List[Dict[str, Any]]:
        """Execute agents in parallel using ParallelAgentManager."""
        if not self.parallel_manager:
            self.parallel_manager = ParallelAgentManager(self.orchestrator, max_concurrent)
        
        # Create tasks
        tasks = []
        for agent_id in agents:
            if agent_id in self.orchestrator.elite_agents:
                task = self.parallel_manager.create_task(
                    agent_id=agent_id,
                    description=self.orchestrator.determine_agent_task(agent_id, task_description),
                    priority=PriorityLevel.NORMAL
                )
                tasks.append(task)
        
        # Execute in parallel
        async with self.parallel_manager:
            result = await self.parallel_manager.execute_parallel_session(
                tasks, max_concurrent, 60.0
            )
        
        # Convert to expected format
        results = []
        for task_id, task in self.parallel_manager.completed_tasks.items():
            success = task.status.value == "completed"
            results.append({
                "agent_id": task.agent_id,
                "execution_time": task.execution_time,
                "cost": task.cost,
                "success": success,
                "error": str(task.error) if task.error else None
            })
        
        return results
    
    async def execute_async(
        self, 
        task_description: str, 
        agents: List[str], 
        max_concurrent: int
    ) -> List[Dict[str, Any]]:
        """Execute agents asynchronously."""
        if not self.async_orchestrator:
            self.async_orchestrator = AsyncMultiModelOrchestrator(max_workers=max_concurrent)
            await self.async_orchestrator.__aenter__()
        
        try:
            responses = await execute_async_agents(
                task_description, agents, max_concurrent, 60.0
            )
            
            results = []
            for response in responses:
                success = response.error is None
                results.append({
                    "agent_id": response.agent_id,
                    "execution_time": response.execution_time,
                    "cost": response.cost,
                    "success": success,
                    "error": str(response.error) if response.error else None
                })
            
            return results
            
        except Exception as e:
            # Return error results for all agents
            return [{
                "agent_id": agent_id,
                "execution_time": 0,
                "cost": 0,
                "success": False,
                "error": str(e)
            } for agent_id in agents]
    
    async def execute_thread_pool(self, task_description: str, agents: List[str]) -> List[Dict[str, Any]]:
        """Execute using thread pool."""
        def execute_agent(agent_id):
            # Simulate agent execution
            time.sleep(0.5)
            return {
                "agent_id": agent_id,
                "execution_time": 0.5,
                "cost": 0.001,
                "success": True
            }
        
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor(max_workers=len(agents)) as executor:
            futures = [loop.run_in_executor(executor, execute_agent, agent_id) for agent_id in agents]
            results = await asyncio.gather(*futures)
        
        return results
    
    async def execute_process_pool(self, task_description: str, agents: List[str]) -> List[Dict[str, Any]]:
        """Execute using process pool."""
        def execute_agent(agent_id):
            # Simulate agent execution
            time.sleep(0.5)
            return {
                "agent_id": agent_id,
                "execution_time": 0.5,
                "cost": 0.001,
                "success": True
            }
        
        loop = asyncio.get_event_loop()
        with ProcessPoolExecutor(max_workers=min(len(agents), 4)) as executor:
            futures = [loop.run_in_executor(executor, execute_agent, agent_id) for agent_id in agents]
            results = await asyncio.gather(*futures)
        
        return results
    
    async def monitor_resources_during_execution(
        self, 
        cpu_samples: List[float], 
        memory_samples: List[float]
    ) -> None:
        """Monitor system resources during execution."""
        try:
            while True:
                cpu_samples.append(psutil.cpu_percent())
                memory_samples.append(psutil.virtual_memory().percent)
                await asyncio.sleep(0.1)
        except asyncio.CancelledError:
            pass
    
    async def get_system_metrics(self) -> Dict[str, float]:
        """Get current system metrics."""
        return {
            "cpu_percent": psutil.cpu_percent(),
            "memory_percent": psutil.virtual_memory().percent,
            "disk_percent": psutil.disk_usage('/').percent,
            "load_average": psutil.getloadavg()[0] if hasattr(psutil, 'getloadavg') else 0
        }
    
    def calculate_summary(self, results: Dict[ExecutionMode, List[ExecutionResult]]) -> Dict[str, Any]:
        """Calculate summary statistics across all modes."""
        summary = {}
        
        for mode, mode_results in results.items():
            if not mode_results:
                continue
            
            summary[mode.value] = {
                "avg_execution_time": statistics.mean([r.execution_time for r in mode_results]),
                "avg_cost": statistics.mean([r.total_cost for r in mode_results]),
                "avg_throughput": statistics.mean([r.throughput for r in mode_results]),
                "avg_success_rate": statistics.mean([r.successful_tasks / (r.successful_tasks + r.failed_tasks) for r in mode_results]),
                "p95_latency": statistics.mean([r.latency_p95 for r in mode_results]),
                "avg_cpu_usage": statistics.mean([r.cpu_usage_avg for r in mode_results]),
                "avg_memory_usage": statistics.mean([r.memory_usage_avg for r in mode_results]),
                "iterations": len(mode_results)
            }
        
        return summary
    
    def calculate_comparisons(self, results: Dict[ExecutionMode, List[ExecutionResult]]) -> Dict[str, Dict[str, float]]:
        """Calculate performance comparisons between modes."""
        comparisons = {}
        
        if len(results) < 2:
            return comparisons
        
        # Use sequential as baseline if available, otherwise use first mode
        baseline_mode = ExecutionMode.SEQUENTIAL if ExecutionMode.SEQUENTIAL in results else list(results.keys())[0]
        baseline_results = results[baseline_mode]
        
        if not baseline_results:
            return comparisons
        
        baseline_time = statistics.mean([r.execution_time for r in baseline_results])
        baseline_cost = statistics.mean([r.total_cost for r in baseline_results])
        baseline_throughput = statistics.mean([r.throughput for r in baseline_results])
        
        for mode, mode_results in results.items():
            if mode == baseline_mode or not mode_results:
                continue
            
            avg_time = statistics.mean([r.execution_time for r in mode_results])
            avg_cost = statistics.mean([r.total_cost for r in mode_results])
            avg_throughput = statistics.mean([r.throughput for r in mode_results])
            
            comparisons[f"{mode.value}_vs_{baseline_mode.value}"] = {
                "time_improvement": ((baseline_time - avg_time) / baseline_time * 100) if baseline_time > 0 else 0,
                "cost_difference": ((avg_cost - baseline_cost) / baseline_cost * 100) if baseline_cost > 0 else 0,
                "throughput_improvement": ((avg_throughput - baseline_throughput) / baseline_throughput * 100) if baseline_throughput > 0 else 0,
                "speedup_factor": baseline_time / avg_time if avg_time > 0 else 0
            }
        
        return comparisons
    
    def generate_recommendations(self, results: Dict[ExecutionMode, List[ExecutionResult]]) -> List[str]:
        """Generate performance recommendations based on results."""
        recommendations = []
        
        if len(results) < 2:
            return recommendations
        
        # Calculate average metrics for each mode
        mode_metrics = {}
        for mode, mode_results in results.items():
            if mode_results:
                mode_metrics[mode] = {
                    "avg_time": statistics.mean([r.execution_time for r in mode_results]),
                    "avg_cost": statistics.mean([r.total_cost for r in mode_results]),
                    "avg_throughput": statistics.mean([r.throughput for r in mode_results]),
                    "success_rate": statistics.mean([r.successful_tasks / (r.successful_tasks + r.failed_tasks) for r in mode_results])
                }
        
        # Find best performing modes
        if mode_metrics:
            fastest_mode = min(mode_metrics.items(), key=lambda x: x[1]["avg_time"])
            cheapest_mode = min(mode_metrics.items(), key=lambda x: x[1]["avg_cost"])
            highest_throughput = max(mode_metrics.items(), key=lambda x: x[1]["avg_throughput"])
            
            if fastest_mode[1]["avg_time"] > 0:
                recommendations.append(f"🏃 Fastest execution: {fastest_mode[0].value} ({fastest_mode[1]['avg_time']:.2f}s average)")
            
            if cheapest_mode[1]["avg_cost"] > 0:
                recommendations.append(f"💰 Most cost-effective: {cheapest_mode[0].value} (${cheapest_mode[1]['avg_cost']:.4f} average)")
            
            if highest_throughput[1]["avg_throughput"] > 0:
                recommendations.append(f"🚀 Highest throughput: {highest_throughput[0].value} ({highest_throughput[1]['avg_throughput']:.2f} tasks/sec)")
            
            # Performance improvement recommendations
            if ExecutionMode.PARALLEL in mode_metrics and ExecutionMode.SEQUENTIAL in mode_metrics:
                parallel_time = mode_metrics[ExecutionMode.PARALLEL]["avg_time"]
                sequential_time = mode_metrics[ExecutionMode.SEQUENTIAL]["avg_time"]
                
                if parallel_time < sequential_time:
                    improvement = (sequential_time - parallel_time) / sequential_time * 100
                    recommendations.append(f"⚡ Parallel processing provides {improvement:.1f}% time reduction")
                
            # Cost optimization recommendations
            cost_values = [metrics["avg_cost"] for metrics in mode_metrics.values()]
            if max(cost_values) > min(cost_values) * 1.2:  # 20% difference
                recommendations.append("💡 Consider using the most cost-effective execution mode for production workloads")
            
            # Scalability recommendations
            if ExecutionMode.ASYNC in mode_metrics:
                async_metrics = mode_metrics[ExecutionMode.ASYNC]
                if async_metrics["avg_throughput"] > 2.0:  # High throughput
                    recommendations.append("🔄 Async execution shows good scalability characteristics")
        
        return recommendations
    
    async def save_report(self, report: BenchmarkReport, name: str) -> None:
        """Save benchmark report to files."""
        # Save JSON report
        json_file = self.output_dir / f"{name}_report.json"
        with open(json_file, 'w') as f:
            json.dump(asdict(report), f, indent=2, default=str)
        
        # Save CSV data
        csv_file = self.output_dir / f"{name}_results.csv"
        self.export_to_csv(report, csv_file)
        
        # Generate visualizations
        await self.generate_visualizations(report, name)
        
        self.logger.info(f"📄 Report saved: {json_file}")
    
    def export_to_csv(self, report: BenchmarkReport, csv_file: Path) -> None:
        """Export results to CSV format."""
        rows = []
        
        for mode, results in report.results.items():
            for i, result in enumerate(results):
                rows.append({
                    "benchmark": report.config.name,
                    "mode": mode.value,
                    "iteration": i + 1,
                    "execution_time": result.execution_time,
                    "total_cost": result.total_cost,
                    "successful_tasks": result.successful_tasks,
                    "failed_tasks": result.failed_tasks,
                    "throughput": result.throughput,
                    "latency_p50": result.latency_p50,
                    "latency_p95": result.latency_p95,
                    "cpu_usage_avg": result.cpu_usage_avg,
                    "memory_usage_avg": result.memory_usage_avg
                })
        
        if rows:
            df = pd.DataFrame(rows)
            df.to_csv(csv_file, index=False)
    
    async def generate_visualizations(self, report: BenchmarkReport, name: str) -> None:
        """Generate visualization charts."""
        try:
            # Set style
            plt.style.use('seaborn-v0_8')
            sns.set_palette("husl")
            
            # Create figure with subplots
            fig, axes = plt.subplots(2, 2, figsize=(16, 12))
            fig.suptitle(f'Performance Benchmark: {report.config.name}', fontsize=16, fontweight='bold')
            
            # Prepare data
            modes = []
            execution_times = []
            costs = []
            throughputs = []
            cpu_usage = []
            
            for mode, results in report.results.items():
                if results:
                    modes.extend([mode.value] * len(results))
                    execution_times.extend([r.execution_time for r in results])
                    costs.extend([r.total_cost for r in results])
                    throughputs.extend([r.throughput for r in results])
                    cpu_usage.extend([r.cpu_usage_avg for r in results])
            
            if not modes:
                return
            
            df = pd.DataFrame({
                'Mode': modes,
                'Execution_Time': execution_times,
                'Cost': costs,
                'Throughput': throughputs,
                'CPU_Usage': cpu_usage
            })
            
            # Execution time comparison
            sns.boxplot(data=df, x='Mode', y='Execution_Time', ax=axes[0, 0])
            axes[0, 0].set_title('Execution Time Distribution')
            axes[0, 0].set_ylabel('Time (seconds)')
            axes[0, 0].tick_params(axis='x', rotation=45)
            
            # Cost comparison
            sns.boxplot(data=df, x='Mode', y='Cost', ax=axes[0, 1])
            axes[0, 1].set_title('Cost Distribution')
            axes[0, 1].set_ylabel('Cost ($)')
            axes[0, 1].tick_params(axis='x', rotation=45)
            
            # Throughput comparison
            sns.boxplot(data=df, x='Mode', y='Throughput', ax=axes[1, 0])
            axes[1, 0].set_title('Throughput Distribution')
            axes[1, 0].set_ylabel('Tasks/second')
            axes[1, 0].tick_params(axis='x', rotation=45)
            
            # CPU usage comparison
            sns.boxplot(data=df, x='Mode', y='CPU_Usage', ax=axes[1, 1])
            axes[1, 1].set_title('CPU Usage Distribution')
            axes[1, 1].set_ylabel('CPU Usage (%)')
            axes[1, 1].tick_params(axis='x', rotation=45)
            
            plt.tight_layout()
            
            # Save plot
            plot_file = self.output_dir / f"{name}_visualization.png"
            plt.savefig(plot_file, dpi=300, bbox_inches='tight')
            plt.close()
            
            self.logger.info(f"📊 Visualization saved: {plot_file}")
            
        except Exception as e:
            self.logger.error(f"Failed to generate visualizations: {e}")
    
    async def generate_comparison_report(self, reports: Dict[str, BenchmarkReport]) -> Dict[str, Any]:
        """Generate comprehensive comparison report across all benchmarks."""
        comparison = {
            "generated_at": datetime.now().isoformat(),
            "total_benchmarks": len(reports),
            "overall_trends": {},
            "mode_performance": {},
            "scalability_analysis": {},
            "cost_analysis": {},
            "recommendations": []
        }
        
        # Aggregate data across all benchmarks
        all_mode_data = defaultdict(list)
        
        for benchmark_name, report in reports.items():
            for mode, results in report.results.items():
                for result in results:
                    all_mode_data[mode.value].append({
                        "benchmark": benchmark_name,
                        "execution_time": result.execution_time,
                        "cost": result.total_cost,
                        "throughput": result.throughput,
                        "cpu_usage": result.cpu_usage_avg
                    })
        
        # Analyze mode performance
        for mode, data in all_mode_data.items():
            if data:
                comparison["mode_performance"][mode] = {
                    "avg_execution_time": statistics.mean([d["execution_time"] for d in data]),
                    "avg_cost": statistics.mean([d["cost"] for d in data]),
                    "avg_throughput": statistics.mean([d["throughput"] for d in data]),
                    "avg_cpu_usage": statistics.mean([d["cpu_usage"] for d in data]),
                    "total_samples": len(data)
                }
        
        # Generate overall recommendations
        if comparison["mode_performance"]:
            fastest_mode = min(comparison["mode_performance"].items(), key=lambda x: x[1]["avg_execution_time"])
            cheapest_mode = min(comparison["mode_performance"].items(), key=lambda x: x[1]["avg_cost"])
            
            comparison["recommendations"].extend([
                f"🏆 Overall fastest execution mode: {fastest_mode[0]}",
                f"💰 Overall most cost-effective mode: {cheapest_mode[0]}",
                "📊 Consider workload characteristics when choosing execution mode",
                "🔧 Monitor resource usage and costs in production environments"
            ])
        
        return comparison
    
    async def save_comparison_report(self, comparison: Dict[str, Any]) -> None:
        """Save comprehensive comparison report."""
        report_file = self.output_dir / "comprehensive_comparison.json"
        with open(report_file, 'w') as f:
            json.dump(comparison, f, indent=2, default=str)
        
        # Generate summary markdown
        md_file = self.output_dir / "benchmark_summary.md"
        await self.generate_markdown_summary(comparison, md_file)
        
        self.logger.info(f"📋 Comprehensive report saved: {report_file}")
    
    async def generate_markdown_summary(self, comparison: Dict[str, Any], md_file: Path) -> None:
        """Generate markdown summary report."""
        with open(md_file, 'w') as f:
            f.write("# Exxede Agent System Performance Benchmark Report\n\n")
            f.write(f"**Generated:** {comparison['generated_at']}\n")
            f.write(f"**Total Benchmarks:** {comparison['total_benchmarks']}\n\n")
            
            f.write("## Overall Performance Summary\n\n")
            
            if comparison["mode_performance"]:
                f.write("| Execution Mode | Avg Time (s) | Avg Cost ($) | Avg Throughput | Avg CPU (%) |\n")
                f.write("|----------------|--------------|--------------|----------------|-------------|\n")
                
                for mode, metrics in comparison["mode_performance"].items():
                    f.write(f"| {mode} | {metrics['avg_execution_time']:.2f} | {metrics['avg_cost']:.4f} | {metrics['avg_throughput']:.2f} | {metrics['avg_cpu_usage']:.1f} |\n")
                
                f.write("\n")
            
            f.write("## Key Recommendations\n\n")
            for rec in comparison["recommendations"]:
                f.write(f"- {rec}\n")
            
            f.write("\n---\n\n")
            f.write("*This report was generated by the Exxede Agent System Performance Benchmark Suite*\n")


async def main():
    """Run performance benchmarks."""
    print("🚀 Exxede Agent System Performance Benchmark Suite")
    print("=" * 60)
    
    # Create benchmark system
    benchmark = PerformanceBenchmark()
    
    try:
        # Run all benchmarks
        reports = await benchmark.run_all_benchmarks()
        
        print(f"\n✅ Benchmark suite completed successfully!")
        print(f"📊 Generated {len(reports)} benchmark reports")
        print(f"📁 Results saved to: {benchmark.output_dir}")
        
        # Show quick summary
        print(f"\n📋 Quick Summary:")
        for name, report in reports.items():
            if report.summary:
                fastest_mode = min(report.summary.items(), key=lambda x: x[1]["avg_execution_time"])
                print(f"  • {name}: Fastest mode = {fastest_mode[0]} ({fastest_mode[1]['avg_execution_time']:.2f}s)")
        
        print(f"\n💡 Check {benchmark.output_dir}/benchmark_summary.md for detailed analysis")
        
    except Exception as e:
        print(f"❌ Benchmark failed: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    exit(exit_code)