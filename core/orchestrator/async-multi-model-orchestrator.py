#!/usr/bin/env python3
"""
Async Multi-Model Orchestrator - Enhanced Enterprise Edition
Advanced async processing with intelligent load balancing and cost optimization
"""

import asyncio
import aiohttp
import json
import time
import uuid
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Callable, Tuple, Union, AsyncGenerator
from dataclasses import dataclass, field, asdict
from enum import Enum
import concurrent.futures
from pathlib import Path
import logging
import weakref
from collections import defaultdict, deque
import heapq
import statistics
from contextlib import asynccontextmanager
import ssl
import certifi

from multi_model_orchestrator import (
    MultiModelOrchestrator, ClaudeModel, AgentCapability, 
    TaskComplexity, AgentCapability
)

class ModelEndpoint(Enum):
    ANTHROPIC_API = "https://api.anthropic.com/v1/messages"
    CLAUDE_CHAT = "claude.ai/chat"
    VERTEX_AI = "vertex-ai-claude"
    BEDROCK = "bedrock-claude"

class LoadBalancingStrategy(Enum):
    ROUND_ROBIN = "round_robin"
    LEAST_LOADED = "least_loaded"
    RESPONSE_TIME = "response_time"
    COST_OPTIMAL = "cost_optimal"
    INTELLIGENT = "intelligent"

class CacheStrategy(Enum):
    NONE = "none"
    MEMORY = "memory"
    DISK = "disk"
    REDIS = "redis"
    HYBRID = "hybrid"

@dataclass
class ModelEndpointConfig:
    endpoint: ModelEndpoint
    api_key: Optional[str] = None
    base_url: str = ""
    max_concurrent: int = 10
    timeout: float = 300.0
    retry_count: int = 3
    circuit_breaker_threshold: int = 5
    cost_multiplier: float = 1.0
    latency_weight: float = 1.0
    enabled: bool = True

@dataclass
class AsyncTaskRequest:
    task_id: str
    agent_id: str
    model: ClaudeModel
    prompt: str
    context: Dict[str, Any]
    priority: int = 1
    timeout: float = 300.0
    retry_count: int = 3
    created_at: datetime = field(default_factory=datetime.now)
    dependencies: List[str] = field(default_factory=list)
    callback: Optional[Callable] = None
    stream: bool = False

@dataclass
class AsyncTaskResponse:
    task_id: str
    agent_id: str
    model: ClaudeModel
    response: Any
    execution_time: float
    token_usage: Dict[str, int]
    cost: float
    endpoint_used: ModelEndpoint
    cached: bool = False
    error: Optional[Exception] = None
    completed_at: datetime = field(default_factory=datetime.now)

@dataclass
class ModelPerformanceMetrics:
    endpoint: ModelEndpoint
    model: ClaudeModel
    request_count: int = 0
    success_count: int = 0
    error_count: int = 0
    total_latency: float = 0.0
    total_cost: float = 0.0
    total_tokens: Dict[str, int] = field(default_factory=lambda: defaultdict(int))
    circuit_breaker_failures: int = 0
    last_success: Optional[datetime] = None
    last_failure: Optional[datetime] = None
    
    @property
    def success_rate(self) -> float:
        return self.success_count / max(self.request_count, 1)
    
    @property
    def average_latency(self) -> float:
        return self.total_latency / max(self.success_count, 1)
    
    @property
    def cost_per_token(self) -> float:
        total_tokens = sum(self.total_tokens.values())
        return self.total_cost / max(total_tokens, 1)

class CircuitBreaker:
    """Circuit breaker pattern for endpoint reliability."""
    
    def __init__(self, failure_threshold: int = 5, timeout: float = 60.0):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
    
    def can_execute(self) -> bool:
        """Check if request can be executed."""
        if self.state == "CLOSED":
            return True
        elif self.state == "OPEN":
            if time.time() - self.last_failure_time > self.timeout:
                self.state = "HALF_OPEN"
                return True
            return False
        else:  # HALF_OPEN
            return True
    
    def record_success(self) -> None:
        """Record successful execution."""
        self.failure_count = 0
        self.state = "CLOSED"
    
    def record_failure(self) -> None:
        """Record failed execution."""
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.failure_count >= self.failure_threshold:
            self.state = "OPEN"

class ResponseCache:
    """Intelligent response caching system."""
    
    def __init__(self, strategy: CacheStrategy = CacheStrategy.MEMORY, max_size: int = 1000):
        self.strategy = strategy
        self.max_size = max_size
        self.cache = {}
        self.access_times = {}
        self.access_counts = defaultdict(int)
        
    def _get_cache_key(self, agent_id: str, model: ClaudeModel, prompt: str) -> str:
        """Generate cache key for request."""
        import hashlib
        content = f"{agent_id}:{model.value['name']}:{prompt}"
        return hashlib.sha256(content.encode()).hexdigest()[:16]
    
    def get(self, agent_id: str, model: ClaudeModel, prompt: str) -> Optional[AsyncTaskResponse]:
        """Get cached response."""
        if self.strategy == CacheStrategy.NONE:
            return None
        
        key = self._get_cache_key(agent_id, model, prompt)
        
        if key in self.cache:
            self.access_times[key] = time.time()
            self.access_counts[key] += 1
            
            # Return copy with cached flag
            cached_response = self.cache[key]
            cached_response.cached = True
            return cached_response
        
        return None
    
    def set(self, agent_id: str, model: ClaudeModel, prompt: str, response: AsyncTaskResponse) -> None:
        """Cache response."""
        if self.strategy == CacheStrategy.NONE:
            return
        
        key = self._get_cache_key(agent_id, model, prompt)
        
        # Evict if at capacity
        if len(self.cache) >= self.max_size:
            self._evict_lru()
        
        self.cache[key] = response
        self.access_times[key] = time.time()
        self.access_counts[key] = 1
    
    def _evict_lru(self) -> None:
        """Evict least recently used item."""
        if not self.access_times:
            return
        
        lru_key = min(self.access_times.items(), key=lambda x: x[1])[0]
        del self.cache[lru_key]
        del self.access_times[lru_key]
        del self.access_counts[lru_key]
    
    def clear(self) -> None:
        """Clear cache."""
        self.cache.clear()
        self.access_times.clear()
        self.access_counts.clear()
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        return {
            "size": len(self.cache),
            "max_size": self.max_size,
            "hit_rate": len(self.cache) / max(len(self.access_counts), 1),
            "total_accesses": sum(self.access_counts.values())
        }

class LoadBalancer:
    """Intelligent load balancer for model endpoints."""
    
    def __init__(self, strategy: LoadBalancingStrategy = LoadBalancingStrategy.INTELLIGENT):
        self.strategy = strategy
        self.endpoint_metrics = defaultdict(lambda: defaultdict(ModelPerformanceMetrics))
        self.active_connections = defaultdict(int)
        self.request_history = deque(maxlen=1000)
        
    def select_endpoint(
        self, 
        model: ClaudeModel, 
        available_endpoints: List[ModelEndpointConfig],
        context: Dict[str, Any] = None
    ) -> Optional[ModelEndpointConfig]:
        """Select optimal endpoint based on strategy."""
        
        # Filter enabled endpoints
        enabled_endpoints = [ep for ep in available_endpoints if ep.enabled]
        if not enabled_endpoints:
            return None
        
        if self.strategy == LoadBalancingStrategy.ROUND_ROBIN:
            return self._round_robin_selection(enabled_endpoints)
        elif self.strategy == LoadBalancingStrategy.LEAST_LOADED:
            return self._least_loaded_selection(enabled_endpoints)
        elif self.strategy == LoadBalancingStrategy.RESPONSE_TIME:
            return self._response_time_selection(model, enabled_endpoints)
        elif self.strategy == LoadBalancingStrategy.COST_OPTIMAL:
            return self._cost_optimal_selection(model, enabled_endpoints)
        else:  # INTELLIGENT
            return self._intelligent_selection(model, enabled_endpoints, context)
    
    def _round_robin_selection(self, endpoints: List[ModelEndpointConfig]) -> ModelEndpointConfig:
        """Simple round-robin selection."""
        total_requests = len(self.request_history)
        return endpoints[total_requests % len(endpoints)]
    
    def _least_loaded_selection(self, endpoints: List[ModelEndpointConfig]) -> ModelEndpointConfig:
        """Select endpoint with least active connections."""
        return min(endpoints, key=lambda ep: self.active_connections[ep.endpoint])
    
    def _response_time_selection(
        self, 
        model: ClaudeModel, 
        endpoints: List[ModelEndpointConfig]
    ) -> ModelEndpointConfig:
        """Select endpoint with best response time."""
        def get_avg_latency(endpoint: ModelEndpointConfig) -> float:
            metrics = self.endpoint_metrics[endpoint.endpoint][model]
            return metrics.average_latency if metrics.success_count > 0 else float('inf')
        
        return min(endpoints, key=get_avg_latency)
    
    def _cost_optimal_selection(
        self, 
        model: ClaudeModel, 
        endpoints: List[ModelEndpointConfig]
    ) -> ModelEndpointConfig:
        """Select most cost-effective endpoint."""
        def get_cost_score(endpoint: ModelEndpointConfig) -> float:
            metrics = self.endpoint_metrics[endpoint.endpoint][model]
            base_cost = metrics.cost_per_token if metrics.total_cost > 0 else 1.0
            return base_cost * endpoint.cost_multiplier
        
        return min(endpoints, key=get_cost_score)
    
    def _intelligent_selection(
        self, 
        model: ClaudeModel, 
        endpoints: List[ModelEndpointConfig],
        context: Dict[str, Any] = None
    ) -> ModelEndpointConfig:
        """Intelligent selection based on multiple factors."""
        context = context or {}
        
        scores = []
        for endpoint in endpoints:
            metrics = self.endpoint_metrics[endpoint.endpoint][model]
            
            # Base score factors
            success_rate = metrics.success_rate
            latency_score = 1.0 / (metrics.average_latency + 1.0) if metrics.success_count > 0 else 0.5
            load_score = 1.0 / (self.active_connections[endpoint.endpoint] + 1.0)
            cost_score = 1.0 / (metrics.cost_per_token * endpoint.cost_multiplier + 0.001)
            
            # Weighted composite score
            score = (
                success_rate * 0.3 +
                latency_score * 0.25 +
                load_score * 0.2 +
                cost_score * 0.15 +
                (1.0 if metrics.last_success else 0.5) * 0.1  # Recent success bonus
            )
            
            # Penalties
            if metrics.circuit_breaker_failures > 0:
                score *= 0.5  # Penalty for circuit breaker failures
            
            scores.append((score, endpoint))
        
        # Return endpoint with highest score
        return max(scores, key=lambda x: x[0])[1]
    
    def record_request(self, endpoint: ModelEndpoint, model: ClaudeModel) -> None:
        """Record request start."""
        self.active_connections[endpoint] += 1
        self.request_history.append((time.time(), endpoint, model))
    
    def record_response(
        self, 
        endpoint: ModelEndpoint, 
        model: ClaudeModel,
        success: bool,
        latency: float,
        cost: float = 0.0,
        tokens: Dict[str, int] = None
    ) -> None:
        """Record request completion."""
        self.active_connections[endpoint] = max(0, self.active_connections[endpoint] - 1)
        
        metrics = self.endpoint_metrics[endpoint][model]
        metrics.request_count += 1
        
        if success:
            metrics.success_count += 1
            metrics.total_latency += latency
            metrics.total_cost += cost
            metrics.last_success = datetime.now()
            
            if tokens:
                for key, value in tokens.items():
                    metrics.total_tokens[key] += value
        else:
            metrics.error_count += 1
            metrics.last_failure = datetime.now()
    
    def get_performance_summary(self) -> Dict[str, Any]:
        """Get performance summary across all endpoints."""
        summary = {
            "total_requests": len(self.request_history),
            "active_connections": dict(self.active_connections),
            "endpoint_performance": {}
        }
        
        for endpoint, models in self.endpoint_metrics.items():
            endpoint_summary = {
                "models": {}
            }
            
            for model, metrics in models.items():
                endpoint_summary["models"][model.value["name"]] = {
                    "requests": metrics.request_count,
                    "success_rate": metrics.success_rate,
                    "avg_latency": metrics.average_latency,
                    "total_cost": metrics.total_cost,
                    "cost_per_token": metrics.cost_per_token
                }
            
            summary["endpoint_performance"][endpoint.value] = endpoint_summary
        
        return summary

class AsyncMultiModelOrchestrator:
    """Enhanced async multi-model orchestrator with enterprise features."""
    
    def __init__(
        self,
        project_dir: str = None,
        max_workers: int = 20,
        load_balancing: LoadBalancingStrategy = LoadBalancingStrategy.INTELLIGENT,
        cache_strategy: CacheStrategy = CacheStrategy.MEMORY
    ):
        self.base_orchestrator = MultiModelOrchestrator(project_dir)
        self.project_dir = Path(project_dir or self.base_orchestrator.project_dir)
        self.max_workers = max_workers
        
        # Async components
        self.session_pool = {}
        self.task_queue = asyncio.PriorityQueue()
        self.active_tasks = {}
        self.completed_tasks = {}
        
        # Performance optimization
        self.load_balancer = LoadBalancer(load_balancing)
        self.cache = ResponseCache(cache_strategy)
        self.circuit_breakers = defaultdict(CircuitBreaker)
        
        # Configuration
        self.endpoints = self._initialize_endpoints()
        self.semaphore = asyncio.Semaphore(max_workers)
        
        # Monitoring
        self.performance_metrics = defaultdict(lambda: defaultdict(int))
        self.cost_tracker = {
            "total_cost": 0.0,
            "total_tokens": defaultdict(int),
            "cost_by_model": defaultdict(float),
            "cost_by_agent": defaultdict(float)
        }
        
        # Setup logging
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.INFO)
    
    def _initialize_endpoints(self) -> List[ModelEndpointConfig]:
        """Initialize available model endpoints."""
        return [
            ModelEndpointConfig(
                endpoint=ModelEndpoint.ANTHROPIC_API,
                base_url="https://api.anthropic.com/v1",
                max_concurrent=10,
                timeout=300.0,
                cost_multiplier=1.0,
                enabled=True
            ),
            ModelEndpointConfig(
                endpoint=ModelEndpoint.VERTEX_AI,
                base_url="vertex-ai-endpoint",
                max_concurrent=15,
                timeout=200.0,
                cost_multiplier=0.8,  # Slightly cheaper
                enabled=False  # Disabled by default
            ),
            ModelEndpointConfig(
                endpoint=ModelEndpoint.BEDROCK,
                base_url="bedrock-endpoint",
                max_concurrent=12,
                timeout=250.0,
                cost_multiplier=0.9,
                enabled=False  # Disabled by default
            )
        ]
    
    async def __aenter__(self):
        """Async context manager entry."""
        await self._initialize_sessions()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        await self._cleanup_sessions()
    
    async def _initialize_sessions(self) -> None:
        """Initialize HTTP sessions for endpoints."""
        ssl_context = ssl.create_default_context(cafile=certifi.where())
        connector = aiohttp.TCPConnector(
            limit=self.max_workers * 2,
            limit_per_host=self.max_workers,
            ssl=ssl_context
        )
        
        timeout = aiohttp.ClientTimeout(total=300, connect=30)
        
        for endpoint_config in self.endpoints:
            if endpoint_config.enabled:
                session = aiohttp.ClientSession(
                    connector=connector,
                    timeout=timeout,
                    headers={"User-Agent": "Exxede-Agent-System/2.0"}
                )
                self.session_pool[endpoint_config.endpoint] = session
        
        self.logger.info(f"Initialized {len(self.session_pool)} endpoint sessions")
    
    async def _cleanup_sessions(self) -> None:
        """Cleanup HTTP sessions."""
        for session in self.session_pool.values():
            await session.close()
        self.session_pool.clear()
        self.logger.info("Cleaned up endpoint sessions")
    
    async def submit_task(self, request: AsyncTaskRequest) -> str:
        """Submit task for async execution."""
        # Check cache first
        cached_response = self.cache.get(request.agent_id, request.model, request.prompt)
        if cached_response:
            self.completed_tasks[request.task_id] = cached_response
            self.logger.info(f"Task {request.task_id} served from cache")
            return request.task_id
        
        # Add to queue with priority
        priority = (request.priority, request.created_at.timestamp())
        await self.task_queue.put((priority, request))
        
        self.logger.info(f"Task {request.task_id} submitted for agent {request.agent_id}")
        return request.task_id
    
    async def execute_parallel_batch(
        self,
        requests: List[AsyncTaskRequest],
        max_concurrent: int = None,
        timeout: float = 300.0
    ) -> List[AsyncTaskResponse]:
        """Execute multiple tasks in parallel with intelligent orchestration."""
        max_concurrent = max_concurrent or self.max_workers
        
        # Submit all tasks
        task_ids = []
        for request in requests:
            task_id = await self.submit_task(request)
            task_ids.append(task_id)
        
        # Create worker tasks
        worker_semaphore = asyncio.Semaphore(max_concurrent)
        workers = [
            asyncio.create_task(self._worker_loop(worker_semaphore, timeout))
            for _ in range(max_concurrent)
        ]
        
        # Wait for completion or timeout
        start_time = time.time()
        try:
            await asyncio.wait_for(
                self._wait_for_completion(task_ids),
                timeout=timeout
            )
        except asyncio.TimeoutError:
            self.logger.warning(f"Batch execution timed out after {timeout}s")
        finally:
            # Cancel workers
            for worker in workers:
                worker.cancel()
        
        execution_time = time.time() - start_time
        
        # Collect results
        results = []
        for task_id in task_ids:
            if task_id in self.completed_tasks:
                results.append(self.completed_tasks[task_id])
            else:
                # Create error response for incomplete tasks
                error_response = AsyncTaskResponse(
                    task_id=task_id,
                    agent_id="unknown",
                    model=ClaudeModel.SONNET,
                    response=None,
                    execution_time=execution_time,
                    token_usage={},
                    cost=0.0,
                    endpoint_used=ModelEndpoint.ANTHROPIC_API,
                    error=TimeoutError("Task did not complete within timeout")
                )
                results.append(error_response)
        
        self.logger.info(f"Batch execution completed: {len(results)} tasks in {execution_time:.2f}s")
        return results
    
    async def _worker_loop(self, semaphore: asyncio.Semaphore, timeout: float) -> None:
        """Worker loop for processing tasks."""
        end_time = time.time() + timeout
        
        while time.time() < end_time:
            try:
                async with semaphore:
                    # Get next task with timeout
                    try:
                        priority, request = await asyncio.wait_for(
                            self.task_queue.get(),
                            timeout=1.0
                        )
                    except asyncio.TimeoutError:
                        continue
                    
                    # Execute task
                    response = await self._execute_single_task(request)
                    self.completed_tasks[request.task_id] = response
                    
                    # Call callback if provided
                    if request.callback:
                        try:
                            await request.callback(response)
                        except Exception as e:
                            self.logger.error(f"Callback error for task {request.task_id}: {e}")
            
            except Exception as e:
                self.logger.error(f"Worker error: {e}")
                await asyncio.sleep(0.1)
    
    async def _execute_single_task(self, request: AsyncTaskRequest) -> AsyncTaskResponse:
        """Execute a single task with intelligent endpoint selection."""
        start_time = time.time()
        self.active_tasks[request.task_id] = request
        
        try:
            # Select optimal endpoint
            endpoint_config = self.load_balancer.select_endpoint(
                request.model,
                self.endpoints,
                request.context
            )
            
            if not endpoint_config:
                raise RuntimeError("No available endpoints")
            
            # Check circuit breaker
            circuit_breaker = self.circuit_breakers[endpoint_config.endpoint]
            if not circuit_breaker.can_execute():
                raise RuntimeError(f"Circuit breaker open for {endpoint_config.endpoint}")
            
            # Record request start
            self.load_balancer.record_request(endpoint_config.endpoint, request.model)
            
            # Execute request
            response_data = await self._make_api_request(endpoint_config, request)
            
            # Calculate metrics
            execution_time = time.time() - start_time
            token_usage = self._extract_token_usage(response_data)
            cost = self._calculate_cost(request.model, token_usage)
            
            # Record success
            circuit_breaker.record_success()
            self.load_balancer.record_response(
                endpoint_config.endpoint,
                request.model,
                True,
                execution_time,
                cost,
                token_usage
            )
            
            # Update cost tracking
            self.cost_tracker["total_cost"] += cost
            self.cost_tracker["cost_by_model"][request.model.value["name"]] += cost
            self.cost_tracker["cost_by_agent"][request.agent_id] += cost
            for key, value in token_usage.items():
                self.cost_tracker["total_tokens"][key] += value
            
            # Create response
            response = AsyncTaskResponse(
                task_id=request.task_id,
                agent_id=request.agent_id,
                model=request.model,
                response=response_data,
                execution_time=execution_time,
                token_usage=token_usage,
                cost=cost,
                endpoint_used=endpoint_config.endpoint
            )
            
            # Cache response
            self.cache.set(request.agent_id, request.model, request.prompt, response)
            
            self.logger.info(
                f"Task {request.task_id} completed in {execution_time:.2f}s, "
                f"cost: ${cost:.4f}, endpoint: {endpoint_config.endpoint.value}"
            )
            
            return response
        
        except Exception as e:
            execution_time = time.time() - start_time
            
            # Record failure
            if 'endpoint_config' in locals():
                circuit_breaker.record_failure()
                self.load_balancer.record_response(
                    endpoint_config.endpoint,
                    request.model,
                    False,
                    execution_time
                )
            
            # Create error response
            response = AsyncTaskResponse(
                task_id=request.task_id,
                agent_id=request.agent_id,
                model=request.model,
                response=None,
                execution_time=execution_time,
                token_usage={},
                cost=0.0,
                endpoint_used=endpoint_config.endpoint if 'endpoint_config' in locals() else ModelEndpoint.ANTHROPIC_API,
                error=e
            )
            
            self.logger.error(f"Task {request.task_id} failed: {e}")
            return response
        
        finally:
            self.active_tasks.pop(request.task_id, None)
    
    async def _make_api_request(
        self,
        endpoint_config: ModelEndpointConfig,
        request: AsyncTaskRequest
    ) -> Dict[str, Any]:
        """Make actual API request to endpoint."""
        session = self.session_pool.get(endpoint_config.endpoint)
        if not session:
            raise RuntimeError(f"No session for endpoint {endpoint_config.endpoint}")
        
        # Simulate API request (replace with actual implementation)
        await asyncio.sleep(0.1)  # Simulate network latency
        
        # Mock response
        return {
            "content": f"Agent {request.agent_id} response for: {request.prompt[:100]}...",
            "model": request.model.value["name"],
            "usage": {
                "input_tokens": len(request.prompt.split()) * 4,
                "output_tokens": len(request.prompt.split()) * 6,
                "total_tokens": len(request.prompt.split()) * 10
            }
        }
    
    def _extract_token_usage(self, response_data: Dict[str, Any]) -> Dict[str, int]:
        """Extract token usage from API response."""
        usage = response_data.get("usage", {})
        return {
            "input_tokens": usage.get("input_tokens", 0),
            "output_tokens": usage.get("output_tokens", 0),
            "total_tokens": usage.get("total_tokens", 0)
        }
    
    def _calculate_cost(self, model: ClaudeModel, token_usage: Dict[str, int]) -> float:
        """Calculate cost based on model and token usage."""
        model_info = model.value
        input_cost = (token_usage.get("input_tokens", 0) / 1_000_000) * model_info["input_cost"]
        output_cost = (token_usage.get("output_tokens", 0) / 1_000_000) * model_info["output_cost"]
        return input_cost + output_cost
    
    async def _wait_for_completion(self, task_ids: List[str]) -> None:
        """Wait for all tasks to complete."""
        while True:
            completed = sum(1 for tid in task_ids if tid in self.completed_tasks)
            if completed == len(task_ids):
                break
            
            # Check if queue is empty and no active tasks
            if self.task_queue.empty() and not self.active_tasks:
                break
            
            await asyncio.sleep(0.1)
    
    async def stream_task_results(
        self,
        requests: List[AsyncTaskRequest],
        max_concurrent: int = None
    ) -> AsyncGenerator[AsyncTaskResponse, None]:
        """Stream task results as they complete."""
        max_concurrent = max_concurrent or self.max_workers
        
        # Submit all tasks
        task_ids = set()
        for request in requests:
            task_id = await self.submit_task(request)
            task_ids.add(task_id)
        
        # Create workers
        worker_semaphore = asyncio.Semaphore(max_concurrent)
        workers = [
            asyncio.create_task(self._worker_loop(worker_semaphore, 600.0))
            for _ in range(max_concurrent)
        ]
        
        try:
            # Yield results as they complete
            yielded_tasks = set()
            while len(yielded_tasks) < len(task_ids):
                for task_id in task_ids - yielded_tasks:
                    if task_id in self.completed_tasks:
                        yield self.completed_tasks[task_id]
                        yielded_tasks.add(task_id)
                
                await asyncio.sleep(0.01)  # Small delay to prevent busy waiting
        
        finally:
            # Cancel workers
            for worker in workers:
                worker.cancel()
    
    def get_performance_metrics(self) -> Dict[str, Any]:
        """Get comprehensive performance metrics."""
        return {
            "load_balancer": self.load_balancer.get_performance_summary(),
            "cache": self.cache.get_stats(),
            "cost_tracking": dict(self.cost_tracker),
            "active_tasks": len(self.active_tasks),
            "completed_tasks": len(self.completed_tasks),
            "queue_size": self.task_queue.qsize(),
            "circuit_breakers": {
                endpoint.value: {
                    "state": cb.state,
                    "failure_count": cb.failure_count
                }
                for endpoint, cb in self.circuit_breakers.items()
            }
        }
    
    async def optimize_performance(self) -> Dict[str, Any]:
        """Automatically optimize performance based on metrics."""
        metrics = self.get_performance_metrics()
        optimizations = []
        
        # Cache optimization
        cache_stats = metrics["cache"]
        if cache_stats["hit_rate"] < 0.2 and cache_stats["size"] < cache_stats["max_size"]:
            self.cache.max_size = min(self.cache.max_size * 2, 5000)
            optimizations.append("Increased cache size")
        
        # Load balancer optimization
        lb_metrics = metrics["load_balancer"]
        endpoint_performance = lb_metrics.get("endpoint_performance", {})
        
        # Disable poorly performing endpoints
        for endpoint_name, perf in endpoint_performance.items():
            for model_name, model_perf in perf.get("models", {}).items():
                if model_perf["success_rate"] < 0.5 and model_perf["requests"] > 10:
                    # Find and disable endpoint
                    for endpoint_config in self.endpoints:
                        if endpoint_config.endpoint.value == endpoint_name:
                            endpoint_config.enabled = False
                            optimizations.append(f"Disabled {endpoint_name} due to low success rate")
        
        # Circuit breaker optimization
        cb_metrics = metrics["circuit_breakers"]
        for endpoint_name, cb_data in cb_metrics.items():
            if cb_data["state"] == "OPEN" and cb_data["failure_count"] > 10:
                # Reset circuit breaker after some time
                endpoint = ModelEndpoint(endpoint_name)
                if endpoint in self.circuit_breakers:
                    self.circuit_breakers[endpoint].failure_count = 0
                    self.circuit_breakers[endpoint].state = "CLOSED"
                    optimizations.append(f"Reset circuit breaker for {endpoint_name}")
        
        return {
            "optimizations_applied": optimizations,
            "performance_metrics": metrics
        }


# Convenience functions for easy usage
async def execute_async_agents(
    task_description: str,
    agents: List[str] = None,
    max_concurrent: int = 8,
    timeout: float = 300.0,
    cache_strategy: CacheStrategy = CacheStrategy.MEMORY
) -> List[AsyncTaskResponse]:
    """Execute multiple agents asynchronously for a single task."""
    base_orchestrator = MultiModelOrchestrator()
    
    if not agents:
        agents = base_orchestrator.select_optimal_agents(task_description)
    
    async with AsyncMultiModelOrchestrator(
        max_workers=max_concurrent,
        cache_strategy=cache_strategy
    ) as orchestrator:
        
        # Create async requests
        requests = []
        for agent_id in agents:
            if agent_id in base_orchestrator.elite_agents:
                agent_task = base_orchestrator.determine_agent_task(agent_id, task_description)
                task_complexity = base_orchestrator.classify_task_complexity(agent_task)
                
                agent = base_orchestrator.elite_agents[agent_id]
                model = agent.model_preferences[task_complexity]
                
                request = AsyncTaskRequest(
                    task_id=str(uuid.uuid4()),
                    agent_id=agent_id,
                    model=model,
                    prompt=agent_task,
                    context={"original_task": task_description},
                    priority=1,
                    timeout=timeout
                )
                requests.append(request)
        
        return await orchestrator.execute_parallel_batch(requests, max_concurrent, timeout)


async def stream_agent_responses(
    task_description: str,
    agents: List[str] = None,
    max_concurrent: int = 4
) -> AsyncGenerator[AsyncTaskResponse, None]:
    """Stream agent responses as they complete."""
    base_orchestrator = MultiModelOrchestrator()
    
    if not agents:
        agents = base_orchestrator.select_optimal_agents(task_description)
    
    async with AsyncMultiModelOrchestrator(max_workers=max_concurrent) as orchestrator:
        
        # Create async requests
        requests = []
        for agent_id in agents:
            if agent_id in base_orchestrator.elite_agents:
                agent_task = base_orchestrator.determine_agent_task(agent_id, task_description)
                task_complexity = base_orchestrator.classify_task_complexity(agent_task)
                
                agent = base_orchestrator.elite_agents[agent_id]
                model = agent.model_preferences[task_complexity]
                
                request = AsyncTaskRequest(
                    task_id=str(uuid.uuid4()),
                    agent_id=agent_id,
                    model=model,
                    prompt=agent_task,
                    context={"original_task": task_description}
                )
                requests.append(request)
        
        async for response in orchestrator.stream_task_results(requests, max_concurrent):
            yield response


if __name__ == "__main__":
    async def main():
        """Demo of async multi-model orchestration."""
        print("🚀 Async Multi-Model Orchestrator Demo")
        
        # Execute parallel agents
        responses = await execute_async_agents(
            "Design a mobile app for Dominican Republic tourism market",
            agents=["ARQ", "VEX", "SAGE", "ECHO", "NOVA"],
            max_concurrent=3,
            timeout=60.0
        )
        
        print(f"\n📊 Execution Results:")
        total_cost = sum(r.cost for r in responses)
        total_time = max(r.execution_time for r in responses)
        successful = len([r for r in responses if r.error is None])
        
        print(f"Tasks: {successful}/{len(responses)} successful")
        print(f"Max time: {total_time:.2f}s")
        print(f"Total cost: ${total_cost:.4f}")
        
        print(f"\n🤖 Agent Responses:")
        for response in responses:
            status = "✅" if response.error is None else "❌"
            print(f"  {status} {response.agent_id}: {response.execution_time:.2f}s, ${response.cost:.4f}")
            if response.error:
                print(f"    Error: {response.error}")
        
        # Demo streaming responses
        print(f"\n🌊 Streaming Demo:")
        async for response in stream_agent_responses(
            "Create content strategy for ReppingDR merchandise",
            agents=["ECHO", "VEX", "SAGE"],
            max_concurrent=2
        ):
            print(f"✨ {response.agent_id} completed in {response.execution_time:.2f}s")
    
    asyncio.run(main())