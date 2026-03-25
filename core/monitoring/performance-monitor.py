#!/usr/bin/env python3
"""
Enterprise Performance Monitoring and Cost Optimization System
Real-time monitoring, alerting, and automatic optimization for Exxede Agent System
"""

import asyncio
import json
import time
import psutil
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Callable, Union
from dataclasses import dataclass, field, asdict
from enum import Enum
from pathlib import Path
from collections import defaultdict, deque
import statistics
import threading
import sqlite3
import weakref
import yaml

class MetricType(Enum):
    COUNTER = "counter"
    GAUGE = "gauge"
    HISTOGRAM = "histogram"
    TIMER = "timer"
    COST = "cost"

class AlertLevel(Enum):
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"

class OptimizationAction(Enum):
    SCALE_UP = "scale_up"
    SCALE_DOWN = "scale_down"
    CACHE_INCREASE = "cache_increase"
    MODEL_DOWNGRADE = "model_downgrade"
    MODEL_UPGRADE = "model_upgrade"
    ENABLE_COMPRESSION = "enable_compression"
    DISABLE_FEATURE = "disable_feature"

@dataclass
class Metric:
    name: str
    type: MetricType
    value: Union[float, int]
    timestamp: datetime = field(default_factory=datetime.now)
    labels: Dict[str, str] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class Alert:
    id: str
    level: AlertLevel
    message: str
    metric_name: str
    threshold: float
    current_value: float
    timestamp: datetime = field(default_factory=datetime.now)
    resolved: bool = False
    resolved_at: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class OptimizationSuggestion:
    id: str
    action: OptimizationAction
    description: str
    potential_benefit: str
    confidence: float  # 0.0 to 1.0
    estimated_impact: Dict[str, float]  # cost_reduction, performance_gain, etc.
    prerequisites: List[str] = field(default_factory=list)
    risks: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)

@dataclass
class PerformanceSnapshot:
    timestamp: datetime
    system_metrics: Dict[str, float]
    agent_metrics: Dict[str, Dict[str, float]]
    cost_metrics: Dict[str, float]
    optimization_score: float
    alerts_count: Dict[AlertLevel, int]

class MetricsCollector:
    """Collects and aggregates performance metrics."""
    
    def __init__(self, retention_days: int = 7):
        self.metrics = defaultdict(lambda: deque(maxlen=10000))
        self.retention_days = retention_days
        self.collectors = {}
        self.aggregation_intervals = {
            "1m": 60,
            "5m": 300,
            "1h": 3600,
            "1d": 86400
        }
        self.aggregated_metrics = defaultdict(lambda: defaultdict(deque))
        
    def register_collector(self, name: str, collector_func: Callable) -> None:
        """Register a metric collector function."""
        self.collectors[name] = collector_func
    
    def collect_metric(self, metric: Metric) -> None:
        """Collect a single metric."""
        self.metrics[metric.name].append(metric)
        self._cleanup_old_metrics()
    
    def collect_batch(self, metrics: List[Metric]) -> None:
        """Collect multiple metrics efficiently."""
        for metric in metrics:
            self.metrics[metric.name].append(metric)
        self._cleanup_old_metrics()
    
    async def collect_system_metrics(self) -> List[Metric]:
        """Collect system-level metrics."""
        metrics = []
        now = datetime.now()
        
        # CPU metrics
        cpu_percent = psutil.cpu_percent(interval=1)
        metrics.append(Metric("system.cpu.usage", MetricType.GAUGE, cpu_percent, now))
        
        # Memory metrics
        memory = psutil.virtual_memory()
        metrics.append(Metric("system.memory.usage", MetricType.GAUGE, memory.percent, now))
        metrics.append(Metric("system.memory.available", MetricType.GAUGE, memory.available, now))
        
        # Disk metrics
        disk = psutil.disk_usage('/')
        metrics.append(Metric("system.disk.usage", MetricType.GAUGE, disk.percent, now))
        metrics.append(Metric("system.disk.free", MetricType.GAUGE, disk.free, now))
        
        # Network metrics
        network = psutil.net_io_counters()
        metrics.append(Metric("system.network.bytes_sent", MetricType.COUNTER, network.bytes_sent, now))
        metrics.append(Metric("system.network.bytes_recv", MetricType.COUNTER, network.bytes_recv, now))
        
        # Process metrics
        process = psutil.Process()
        metrics.append(Metric("process.cpu.usage", MetricType.GAUGE, process.cpu_percent(), now))
        metrics.append(Metric("process.memory.rss", MetricType.GAUGE, process.memory_info().rss, now))
        metrics.append(Metric("process.threads", MetricType.GAUGE, process.num_threads(), now))
        
        return metrics
    
    def get_metrics(self, name: str, duration: timedelta = None) -> List[Metric]:
        """Get metrics for a specific name within duration."""
        metrics = list(self.metrics[name])
        
        if duration:
            cutoff = datetime.now() - duration
            metrics = [m for m in metrics if m.timestamp >= cutoff]
        
        return metrics
    
    def get_metric_value(self, name: str, aggregation: str = "latest") -> Optional[float]:
        """Get aggregated metric value."""
        metrics = self.metrics[name]
        if not metrics:
            return None
        
        values = [m.value for m in metrics]
        
        if aggregation == "latest":
            return values[-1]
        elif aggregation == "average":
            return statistics.mean(values)
        elif aggregation == "max":
            return max(values)
        elif aggregation == "min":
            return min(values)
        elif aggregation == "sum":
            return sum(values)
        else:
            return values[-1]
    
    def aggregate_metrics(self) -> None:
        """Aggregate metrics for different time intervals."""
        now = datetime.now()
        
        for interval_name, interval_seconds in self.aggregation_intervals.items():
            cutoff = now - timedelta(seconds=interval_seconds)
            
            for metric_name, metric_list in self.metrics.items():
                recent_metrics = [m for m in metric_list if m.timestamp >= cutoff]
                
                if recent_metrics:
                    values = [m.value for m in recent_metrics]
                    
                    aggregated = {
                        "avg": statistics.mean(values),
                        "max": max(values),
                        "min": min(values),
                        "count": len(values),
                        "sum": sum(values),
                        "timestamp": now
                    }
                    
                    self.aggregated_metrics[interval_name][metric_name].append(aggregated)
                    
                    # Keep only recent aggregations
                    max_aggregations = 1000
                    if len(self.aggregated_metrics[interval_name][metric_name]) > max_aggregations:
                        self.aggregated_metrics[interval_name][metric_name].popleft()
    
    def _cleanup_old_metrics(self) -> None:
        """Remove metrics older than retention period."""
        cutoff = datetime.now() - timedelta(days=self.retention_days)
        
        for metric_name in self.metrics:
            metric_list = self.metrics[metric_name]
            while metric_list and metric_list[0].timestamp < cutoff:
                metric_list.popleft()

class AlertManager:
    """Manages alerts and notifications."""
    
    def __init__(self, metrics_collector: MetricsCollector):
        self.metrics_collector = metrics_collector
        self.alerts = {}
        self.alert_rules = {}
        self.notification_handlers = []
        self.alert_history = deque(maxlen=10000)
        
    def add_alert_rule(
        self,
        rule_name: str,
        metric_name: str,
        condition: str,
        threshold: float,
        level: AlertLevel,
        message_template: str
    ) -> None:
        """Add an alert rule."""
        self.alert_rules[rule_name] = {
            "metric_name": metric_name,
            "condition": condition,  # "gt", "lt", "eq", "ne"
            "threshold": threshold,
            "level": level,
            "message_template": message_template,
            "consecutive_breaches": 0,
            "breach_threshold": 3  # Require 3 consecutive breaches
        }
    
    def add_notification_handler(self, handler: Callable[[Alert], None]) -> None:
        """Add a notification handler for alerts."""
        self.notification_handlers.append(handler)
    
    async def check_alerts(self) -> List[Alert]:
        """Check all alert rules and generate alerts."""
        new_alerts = []
        
        for rule_name, rule in self.alert_rules.items():
            metric_value = self.metrics_collector.get_metric_value(rule["metric_name"])
            
            if metric_value is None:
                continue
            
            # Check condition
            condition_met = False
            if rule["condition"] == "gt" and metric_value > rule["threshold"]:
                condition_met = True
            elif rule["condition"] == "lt" and metric_value < rule["threshold"]:
                condition_met = True
            elif rule["condition"] == "eq" and metric_value == rule["threshold"]:
                condition_met = True
            elif rule["condition"] == "ne" and metric_value != rule["threshold"]:
                condition_met = True
            
            if condition_met:
                rule["consecutive_breaches"] += 1
                
                # Only trigger alert after consecutive breaches
                if rule["consecutive_breaches"] >= rule["breach_threshold"]:
                    alert = Alert(
                        id=f"{rule_name}_{int(time.time())}",
                        level=rule["level"],
                        message=rule["message_template"].format(
                            metric_name=rule["metric_name"],
                            value=metric_value,
                            threshold=rule["threshold"]
                        ),
                        metric_name=rule["metric_name"],
                        threshold=rule["threshold"],
                        current_value=metric_value,
                        metadata={"rule_name": rule_name}
                    )
                    
                    self.alerts[alert.id] = alert
                    self.alert_history.append(alert)
                    new_alerts.append(alert)
                    
                    # Send notifications
                    for handler in self.notification_handlers:
                        try:
                            handler(alert)
                        except Exception as e:
                            logging.error(f"Notification handler error: {e}")
            else:
                rule["consecutive_breaches"] = 0
                
                # Check if we should resolve existing alerts
                existing_alerts = [a for a in self.alerts.values() 
                                 if a.metric_name == rule["metric_name"] and not a.resolved]
                
                for alert in existing_alerts:
                    alert.resolved = True
                    alert.resolved_at = datetime.now()
        
        return new_alerts
    
    def get_active_alerts(self, level: AlertLevel = None) -> List[Alert]:
        """Get active (unresolved) alerts."""
        alerts = [a for a in self.alerts.values() if not a.resolved]
        
        if level:
            alerts = [a for a in alerts if a.level == level]
        
        return sorted(alerts, key=lambda x: x.timestamp, reverse=True)
    
    def resolve_alert(self, alert_id: str) -> bool:
        """Manually resolve an alert."""
        if alert_id in self.alerts:
            self.alerts[alert_id].resolved = True
            self.alerts[alert_id].resolved_at = datetime.now()
            return True
        return False

class CostOptimizer:
    """Analyzes costs and suggests optimizations."""
    
    def __init__(self, metrics_collector: MetricsCollector):
        self.metrics_collector = metrics_collector
        self.cost_history = deque(maxlen=1000)
        self.optimization_history = deque(maxlen=100)
        
    def track_cost(self, operation: str, cost: float, metadata: Dict[str, Any] = None) -> None:
        """Track cost for an operation."""
        cost_entry = {
            "operation": operation,
            "cost": cost,
            "timestamp": datetime.now(),
            "metadata": metadata or {}
        }
        self.cost_history.append(cost_entry)
        
        # Create cost metric
        metric = Metric(
            name=f"cost.{operation}",
            type=MetricType.COST,
            value=cost,
            labels={"operation": operation},
            metadata=metadata or {}
        )
        self.metrics_collector.collect_metric(metric)
    
    def analyze_costs(self, duration: timedelta = timedelta(hours=24)) -> Dict[str, Any]:
        """Analyze costs over a time period."""
        cutoff = datetime.now() - duration
        recent_costs = [entry for entry in self.cost_history if entry["timestamp"] >= cutoff]
        
        if not recent_costs:
            return {"total_cost": 0, "operations": {}, "trends": {}}
        
        # Aggregate by operation
        operations = defaultdict(list)
        for entry in recent_costs:
            operations[entry["operation"]].append(entry["cost"])
        
        operation_stats = {}
        total_cost = 0
        
        for operation, costs in operations.items():
            operation_stats[operation] = {
                "total": sum(costs),
                "average": statistics.mean(costs),
                "count": len(costs),
                "max": max(costs),
                "min": min(costs)
            }
            total_cost += sum(costs)
        
        # Calculate trends
        trends = {}
        for operation in operations:
            operation_costs = [entry for entry in recent_costs if entry["operation"] == operation]
            operation_costs.sort(key=lambda x: x["timestamp"])
            
            if len(operation_costs) > 1:
                recent_avg = statistics.mean([c["cost"] for c in operation_costs[-5:]])
                earlier_avg = statistics.mean([c["cost"] for c in operation_costs[:-5]]) if len(operation_costs) > 5 else recent_avg
                
                trend = "increasing" if recent_avg > earlier_avg * 1.1 else "decreasing" if recent_avg < earlier_avg * 0.9 else "stable"
                trends[operation] = {
                    "trend": trend,
                    "recent_avg": recent_avg,
                    "earlier_avg": earlier_avg,
                    "change_percent": ((recent_avg - earlier_avg) / earlier_avg * 100) if earlier_avg > 0 else 0
                }
        
        return {
            "total_cost": total_cost,
            "operations": operation_stats,
            "trends": trends,
            "analysis_period": str(duration)
        }
    
    def generate_optimizations(self) -> List[OptimizationSuggestion]:
        """Generate cost optimization suggestions."""
        suggestions = []
        cost_analysis = self.analyze_costs()
        
        # High-cost operations optimization
        for operation, stats in cost_analysis["operations"].items():
            if stats["average"] > 0.10:  # High average cost threshold
                suggestions.append(OptimizationSuggestion(
                    id=f"optimize_high_cost_{operation}",
                    action=OptimizationAction.MODEL_DOWNGRADE,
                    description=f"Consider using a more cost-effective model for {operation}",
                    potential_benefit=f"Could reduce costs by 30-60% for {operation} operations",
                    confidence=0.8,
                    estimated_impact={"cost_reduction": stats["average"] * 0.45},
                    prerequisites=["Verify quality requirements"],
                    risks=["Potential quality degradation"]
                ))
        
        # Cache optimization
        cache_hit_rate = self.metrics_collector.get_metric_value("cache.hit_rate", "average")
        if cache_hit_rate and cache_hit_rate < 0.5:
            suggestions.append(OptimizationSuggestion(
                id="increase_cache_size",
                action=OptimizationAction.CACHE_INCREASE,
                description="Increase cache size to improve hit rate and reduce API calls",
                potential_benefit=f"Improve cache hit rate from {cache_hit_rate:.1%} to 70%+",
                confidence=0.9,
                estimated_impact={"cost_reduction": cost_analysis["total_cost"] * 0.25},
                prerequisites=["Available memory"],
                risks=["Increased memory usage"]
            ))
        
        # Parallel processing optimization
        avg_execution_time = self.metrics_collector.get_metric_value("agent.execution_time", "average")
        if avg_execution_time and avg_execution_time > 10.0:  # > 10 seconds
            suggestions.append(OptimizationSuggestion(
                id="enable_parallel_processing",
                action=OptimizationAction.SCALE_UP,
                description="Enable parallel processing to reduce overall execution time",
                potential_benefit="Reduce execution time by 50-70% through parallelization",
                confidence=0.7,
                estimated_impact={"performance_gain": 0.6, "cost_neutral": True},
                prerequisites=["Multiple agents available"],
                risks=["Increased complexity"]
            ))
        
        return suggestions
    
    def apply_optimization(self, suggestion_id: str) -> Dict[str, Any]:
        """Apply an optimization suggestion."""
        # This is a placeholder - actual implementation would depend on the specific optimization
        result = {
            "success": False,
            "message": "Manual application required",
            "suggestion_id": suggestion_id
        }
        
        self.optimization_history.append({
            "suggestion_id": suggestion_id,
            "applied_at": datetime.now(),
            "result": result
        })
        
        return result

class PerformanceMonitor:
    """Main performance monitoring system."""
    
    def __init__(self, data_dir: Path = None, config: Dict[str, Any] = None):
        self.data_dir = data_dir or Path.home() / ".exxede" / "monitoring"
        self.data_dir.mkdir(parents=True, exist_ok=True)
        
        self.config = config or self.load_default_config()
        
        # Initialize components
        self.metrics_collector = MetricsCollector(self.config.get("retention_days", 7))
        self.alert_manager = AlertManager(self.metrics_collector)
        self.cost_optimizer = CostOptimizer(self.metrics_collector)
        
        # Monitoring state
        self.monitoring_active = False
        self.monitoring_tasks = []
        
        # Database for persistence
        self.db_path = self.data_dir / "performance.db"
        self.init_database()
        
        # Setup default alert rules
        self.setup_default_alerts()
        
        # Setup logging
        self.logger = logging.getLogger(__name__)
    
    def load_default_config(self) -> Dict[str, Any]:
        """Load default monitoring configuration."""
        return {
            "collection_interval": 30,  # seconds
            "retention_days": 7,
            "alert_check_interval": 60,
            "cost_analysis_interval": 300,
            "auto_optimize": False,
            "notification_enabled": True,
            "thresholds": {
                "cpu_warning": 80.0,
                "cpu_critical": 95.0,
                "memory_warning": 85.0,
                "memory_critical": 95.0,
                "cost_warning": 10.0,  # per hour
                "cost_critical": 25.0,  # per hour
                "response_time_warning": 30.0,  # seconds
                "response_time_critical": 60.0   # seconds
            }
        }
    
    def init_database(self) -> None:
        """Initialize SQLite database for persistence."""
        with sqlite3.connect(str(self.db_path)) as conn:
            conn.execute('''
                CREATE TABLE IF NOT EXISTS metrics (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    type TEXT NOT NULL,
                    value REAL NOT NULL,
                    timestamp REAL NOT NULL,
                    labels TEXT,
                    metadata TEXT
                )
            ''')
            
            conn.execute('''
                CREATE TABLE IF NOT EXISTS alerts (
                    id TEXT PRIMARY KEY,
                    level TEXT NOT NULL,
                    message TEXT NOT NULL,
                    metric_name TEXT NOT NULL,
                    threshold REAL NOT NULL,
                    current_value REAL NOT NULL,
                    timestamp REAL NOT NULL,
                    resolved INTEGER DEFAULT 0,
                    resolved_at REAL
                )
            ''')
            
            conn.execute('''
                CREATE TABLE IF NOT EXISTS optimizations (
                    id TEXT PRIMARY KEY,
                    action TEXT NOT NULL,
                    description TEXT NOT NULL,
                    confidence REAL NOT NULL,
                    estimated_impact TEXT,
                    applied INTEGER DEFAULT 0,
                    created_at REAL NOT NULL
                )
            ''')
            
            # Create indexes
            conn.execute('CREATE INDEX IF NOT EXISTS idx_metrics_name_timestamp ON metrics (name, timestamp)')
            conn.execute('CREATE INDEX IF NOT EXISTS idx_alerts_timestamp ON alerts (timestamp)')
    
    def setup_default_alerts(self) -> None:
        """Setup default alert rules."""
        thresholds = self.config["thresholds"]
        
        # System resource alerts
        self.alert_manager.add_alert_rule(
            "cpu_warning",
            "system.cpu.usage",
            "gt",
            thresholds["cpu_warning"],
            AlertLevel.WARNING,
            "High CPU usage: {value:.1f}% (threshold: {threshold:.1f}%)"
        )
        
        self.alert_manager.add_alert_rule(
            "cpu_critical",
            "system.cpu.usage",
            "gt",
            thresholds["cpu_critical"],
            AlertLevel.CRITICAL,
            "Critical CPU usage: {value:.1f}% (threshold: {threshold:.1f}%)"
        )
        
        self.alert_manager.add_alert_rule(
            "memory_warning",
            "system.memory.usage",
            "gt",
            thresholds["memory_warning"],
            AlertLevel.WARNING,
            "High memory usage: {value:.1f}% (threshold: {threshold:.1f}%)"
        )
        
        self.alert_manager.add_alert_rule(
            "memory_critical",
            "system.memory.usage",
            "gt",
            thresholds["memory_critical"],
            AlertLevel.CRITICAL,
            "Critical memory usage: {value:.1f}% (threshold: {threshold:.1f}%)"
        )
        
        # Cost alerts
        self.alert_manager.add_alert_rule(
            "cost_warning",
            "cost.total_hourly",
            "gt",
            thresholds["cost_warning"],
            AlertLevel.WARNING,
            "High hourly cost: ${value:.2f} (threshold: ${threshold:.2f})"
        )
        
        # Response time alerts
        self.alert_manager.add_alert_rule(
            "response_time_warning",
            "agent.response_time",
            "gt",
            thresholds["response_time_warning"],
            AlertLevel.WARNING,
            "Slow response time: {value:.1f}s (threshold: {threshold:.1f}s)"
        )
    
    async def start_monitoring(self) -> None:
        """Start the monitoring system."""
        if self.monitoring_active:
            return
        
        self.monitoring_active = True
        
        # Start monitoring tasks
        self.monitoring_tasks = [
            asyncio.create_task(self.metric_collection_loop()),
            asyncio.create_task(self.alert_checking_loop()),
            asyncio.create_task(self.cost_analysis_loop()),
            asyncio.create_task(self.optimization_loop())
        ]
        
        self.logger.info("Performance monitoring started")
    
    async def stop_monitoring(self) -> None:
        """Stop the monitoring system."""
        self.monitoring_active = False
        
        # Cancel monitoring tasks
        for task in self.monitoring_tasks:
            task.cancel()
        
        # Wait for tasks to complete
        await asyncio.gather(*self.monitoring_tasks, return_exceptions=True)
        
        self.monitoring_tasks.clear()
        self.logger.info("Performance monitoring stopped")
    
    async def metric_collection_loop(self) -> None:
        """Main metric collection loop."""
        while self.monitoring_active:
            try:
                # Collect system metrics
                system_metrics = await self.metrics_collector.collect_system_metrics()
                self.metrics_collector.collect_batch(system_metrics)
                
                # Aggregate metrics
                self.metrics_collector.aggregate_metrics()
                
                # Persist metrics to database
                await self.persist_metrics(system_metrics)
                
                await asyncio.sleep(self.config["collection_interval"])
                
            except Exception as e:
                self.logger.error(f"Metric collection error: {e}")
                await asyncio.sleep(5)
    
    async def alert_checking_loop(self) -> None:
        """Alert checking loop."""
        while self.monitoring_active:
            try:
                alerts = await self.alert_manager.check_alerts()
                
                if alerts:
                    await self.persist_alerts(alerts)
                
                await asyncio.sleep(self.config["alert_check_interval"])
                
            except Exception as e:
                self.logger.error(f"Alert checking error: {e}")
                await asyncio.sleep(10)
    
    async def cost_analysis_loop(self) -> None:
        """Cost analysis loop."""
        while self.monitoring_active:
            try:
                cost_analysis = self.cost_optimizer.analyze_costs()
                
                # Create cost metrics
                total_cost_metric = Metric(
                    name="cost.total_hourly",
                    type=MetricType.COST,
                    value=cost_analysis["total_cost"]
                )
                self.metrics_collector.collect_metric(total_cost_metric)
                
                await asyncio.sleep(self.config["cost_analysis_interval"])
                
            except Exception as e:
                self.logger.error(f"Cost analysis error: {e}")
                await asyncio.sleep(30)
    
    async def optimization_loop(self) -> None:
        """Optimization suggestions loop."""
        while self.monitoring_active:
            try:
                if self.config.get("auto_optimize", False):
                    suggestions = self.cost_optimizer.generate_optimizations()
                    
                    # Auto-apply safe optimizations with high confidence
                    for suggestion in suggestions:
                        if suggestion.confidence > 0.9 and suggestion.action in [
                            OptimizationAction.CACHE_INCREASE,
                            OptimizationAction.ENABLE_COMPRESSION
                        ]:
                            self.cost_optimizer.apply_optimization(suggestion.id)
                
                await asyncio.sleep(600)  # Check every 10 minutes
                
            except Exception as e:
                self.logger.error(f"Optimization error: {e}")
                await asyncio.sleep(60)
    
    async def persist_metrics(self, metrics: List[Metric]) -> None:
        """Persist metrics to database."""
        with sqlite3.connect(str(self.db_path)) as conn:
            for metric in metrics:
                conn.execute('''
                    INSERT INTO metrics (name, type, value, timestamp, labels, metadata)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (
                    metric.name,
                    metric.type.value,
                    metric.value,
                    metric.timestamp.timestamp(),
                    json.dumps(metric.labels),
                    json.dumps(metric.metadata)
                ))
    
    async def persist_alerts(self, alerts: List[Alert]) -> None:
        """Persist alerts to database."""
        with sqlite3.connect(str(self.db_path)) as conn:
            for alert in alerts:
                conn.execute('''
                    INSERT OR REPLACE INTO alerts 
                    (id, level, message, metric_name, threshold, current_value, timestamp, resolved, resolved_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    alert.id,
                    alert.level.value,
                    alert.message,
                    alert.metric_name,
                    alert.threshold,
                    alert.current_value,
                    alert.timestamp.timestamp(),
                    int(alert.resolved),
                    alert.resolved_at.timestamp() if alert.resolved_at else None
                ))
    
    def get_performance_snapshot(self) -> PerformanceSnapshot:
        """Get current performance snapshot."""
        # System metrics
        system_metrics = {
            "cpu_usage": self.metrics_collector.get_metric_value("system.cpu.usage") or 0,
            "memory_usage": self.metrics_collector.get_metric_value("system.memory.usage") or 0,
            "disk_usage": self.metrics_collector.get_metric_value("system.disk.usage") or 0
        }
        
        # Agent metrics (placeholder)
        agent_metrics = {}
        
        # Cost metrics
        cost_analysis = self.cost_optimizer.analyze_costs(timedelta(hours=1))
        cost_metrics = {
            "total_cost": cost_analysis["total_cost"],
            "hourly_rate": cost_analysis["total_cost"]  # Assuming 1-hour analysis
        }
        
        # Optimization score (simple calculation)
        optimization_score = self.calculate_optimization_score(system_metrics, cost_metrics)
        
        # Alert counts
        active_alerts = self.alert_manager.get_active_alerts()
        alerts_count = {level: 0 for level in AlertLevel}
        for alert in active_alerts:
            alerts_count[alert.level] += 1
        
        return PerformanceSnapshot(
            timestamp=datetime.now(),
            system_metrics=system_metrics,
            agent_metrics=agent_metrics,
            cost_metrics=cost_metrics,
            optimization_score=optimization_score,
            alerts_count=alerts_count
        )
    
    def calculate_optimization_score(self, system_metrics: Dict[str, float], cost_metrics: Dict[str, float]) -> float:
        """Calculate overall optimization score (0-100)."""
        score = 100.0
        
        # Deduct for high resource usage
        if system_metrics["cpu_usage"] > 80:
            score -= (system_metrics["cpu_usage"] - 80) * 0.5
        
        if system_metrics["memory_usage"] > 80:
            score -= (system_metrics["memory_usage"] - 80) * 0.5
        
        # Deduct for high costs (relative scoring)
        if cost_metrics["hourly_rate"] > 5.0:  # $5/hour threshold
            score -= min(30, (cost_metrics["hourly_rate"] - 5.0) * 3)
        
        return max(0, min(100, score))
    
    def export_metrics(self, duration: timedelta = timedelta(days=1), format: str = "json") -> str:
        """Export metrics data."""
        cutoff = datetime.now() - duration
        
        with sqlite3.connect(str(self.db_path)) as conn:
            cursor = conn.execute('''
                SELECT name, type, value, timestamp, labels, metadata
                FROM metrics
                WHERE timestamp > ?
                ORDER BY timestamp DESC
            ''', (cutoff.timestamp(),))
            
            metrics_data = []
            for row in cursor.fetchall():
                metrics_data.append({
                    "name": row[0],
                    "type": row[1],
                    "value": row[2],
                    "timestamp": datetime.fromtimestamp(row[3]).isoformat(),
                    "labels": json.loads(row[4]),
                    "metadata": json.loads(row[5])
                })
        
        export_data = {
            "export_timestamp": datetime.now().isoformat(),
            "duration": str(duration),
            "metrics": metrics_data
        }
        
        if format == "json":
            return json.dumps(export_data, indent=2)
        elif format == "yaml":
            return yaml.dump(export_data, default_flow_style=False)
        else:
            raise ValueError(f"Unsupported format: {format}")


# Notification handlers
def console_notification_handler(alert: Alert) -> None:
    """Console notification handler."""
    emoji = "🔥" if alert.level == AlertLevel.CRITICAL else "⚠️" if alert.level == AlertLevel.WARNING else "ℹ️"
    print(f"{emoji} ALERT [{alert.level.value.upper()}]: {alert.message}")

def log_notification_handler(alert: Alert) -> None:
    """Log notification handler."""
    logger = logging.getLogger("alerts")
    level_map = {
        AlertLevel.INFO: logger.info,
        AlertLevel.WARNING: logger.warning,
        AlertLevel.ERROR: logger.error,
        AlertLevel.CRITICAL: logger.critical
    }
    level_map[alert.level](f"Alert: {alert.message}")


# Convenience functions
async def create_performance_monitor(
    data_dir: Path = None,
    config: Dict[str, Any] = None,
    enable_console_alerts: bool = True
) -> PerformanceMonitor:
    """Create and configure performance monitor."""
    monitor = PerformanceMonitor(data_dir, config)
    
    if enable_console_alerts:
        monitor.alert_manager.add_notification_handler(console_notification_handler)
        monitor.alert_manager.add_notification_handler(log_notification_handler)
    
    return monitor


if __name__ == "__main__":
    async def main():
        """Demo of performance monitoring system."""
        print("📊 Performance Monitor Demo")
        
        # Create monitor
        monitor = await create_performance_monitor()
        
        try:
            # Start monitoring
            await monitor.start_monitoring()
            print("🚀 Monitoring started...")
            
            # Run for a short time
            await asyncio.sleep(10)
            
            # Get snapshot
            snapshot = monitor.get_performance_snapshot()
            print(f"\n📈 Performance Snapshot:")
            print(f"CPU: {snapshot.system_metrics['cpu_usage']:.1f}%")
            print(f"Memory: {snapshot.system_metrics['memory_usage']:.1f}%")
            print(f"Optimization Score: {snapshot.optimization_score:.1f}/100")
            
            # Check for alerts
            active_alerts = monitor.alert_manager.get_active_alerts()
            if active_alerts:
                print(f"\n🚨 Active Alerts: {len(active_alerts)}")
                for alert in active_alerts[:3]:  # Show first 3
                    print(f"  • {alert.level.value}: {alert.message}")
            else:
                print("\n✅ No active alerts")
            
            # Generate optimizations
            optimizations = monitor.cost_optimizer.generate_optimizations()
            if optimizations:
                print(f"\n💡 Optimization Suggestions: {len(optimizations)}")
                for opt in optimizations[:2]:  # Show first 2
                    print(f"  • {opt.description}")
                    print(f"    Confidence: {opt.confidence:.1%}")
            
        finally:
            await monitor.stop_monitoring()
            print("👋 Monitoring stopped")
    
    asyncio.run(main())