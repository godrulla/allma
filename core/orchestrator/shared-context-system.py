#!/usr/bin/env python3
"""
Advanced Shared Context System for Agent Communication
Enterprise-grade context management with persistence, synchronization, and intelligence
"""

import asyncio
import json
import time
import uuid
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Callable, Set, Union, AsyncGenerator
from dataclasses import dataclass, field, asdict
from enum import Enum
from pathlib import Path
import threading
import queue
import sqlite3
import hashlib
import pickle
import weakref
import logging
from collections import defaultdict, deque
from concurrent.futures import ThreadPoolExecutor
import redis
import yaml

class ContextScope(Enum):
    SESSION = "session"          # Single session only
    PROJECT = "project"          # Entire project
    GLOBAL = "global"           # Across all projects
    AGENT_PRIVATE = "agent_private"  # Private to specific agent
    TEAM = "team"               # Shared among agent team

class ContextType(Enum):
    DATA = "data"               # Raw data
    INSIGHT = "insight"         # Analyzed information
    DECISION = "decision"       # Decision points
    ARTIFACT = "artifact"       # Generated artifacts
    FEEDBACK = "feedback"       # Agent feedback
    DEPENDENCY = "dependency"   # Task dependencies
    METADATA = "metadata"       # System metadata

class ContextPriority(Enum):
    LOW = 1
    NORMAL = 2
    HIGH = 3
    CRITICAL = 4

class ContextAccessLevel(Enum):
    PUBLIC = "public"           # All agents can access
    RESTRICTED = "restricted"   # Specific agents only
    PRIVATE = "private"         # Creating agent only
    SYSTEM = "system"           # System-level context

@dataclass
class ContextItem:
    id: str
    key: str
    value: Any
    context_type: ContextType
    scope: ContextScope
    priority: ContextPriority
    access_level: ContextAccessLevel
    owner_agent: str
    authorized_agents: Set[str] = field(default_factory=set)
    tags: Set[str] = field(default_factory=set)
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    expires_at: Optional[datetime] = None
    access_count: int = 0
    last_accessed_by: Optional[str] = None
    last_accessed_at: Optional[datetime] = None
    dependencies: Set[str] = field(default_factory=set)
    watchers: Set[str] = field(default_factory=set)
    metadata: Dict[str, Any] = field(default_factory=dict)
    version: int = 1
    parent_id: Optional[str] = None
    children_ids: Set[str] = field(default_factory=set)

@dataclass
class ContextSubscription:
    agent_id: str
    pattern: str
    callback: Callable
    filters: Dict[str, Any] = field(default_factory=dict)
    active: bool = True
    created_at: datetime = field(default_factory=datetime.now)
    trigger_count: int = 0

@dataclass
class ContextEvent:
    event_id: str
    event_type: str  # created, updated, deleted, accessed
    context_id: str
    agent_id: str
    timestamp: datetime = field(default_factory=datetime.now)
    details: Dict[str, Any] = field(default_factory=dict)

class ContextStorage:
    """Abstract base for context storage backends."""
    
    async def store(self, item: ContextItem) -> bool:
        raise NotImplementedError
    
    async def retrieve(self, key: str, scope: ContextScope) -> Optional[ContextItem]:
        raise NotImplementedError
    
    async def query(self, filters: Dict[str, Any]) -> List[ContextItem]:
        raise NotImplementedError
    
    async def delete(self, key: str, scope: ContextScope) -> bool:
        raise NotImplementedError
    
    async def cleanup_expired(self) -> int:
        raise NotImplementedError

class SQLiteContextStorage(ContextStorage):
    """SQLite-based context storage for persistence."""
    
    def __init__(self, db_path: Path):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_database()
    
    def _init_database(self):
        """Initialize SQLite database schema."""
        with sqlite3.connect(str(self.db_path)) as conn:
            conn.execute('''
                CREATE TABLE IF NOT EXISTS context_items (
                    id TEXT PRIMARY KEY,
                    key TEXT NOT NULL,
                    value_json TEXT NOT NULL,
                    context_type TEXT NOT NULL,
                    scope TEXT NOT NULL,
                    priority INTEGER NOT NULL,
                    access_level TEXT NOT NULL,
                    owner_agent TEXT NOT NULL,
                    authorized_agents TEXT DEFAULT '',
                    tags TEXT DEFAULT '',
                    created_at REAL NOT NULL,
                    updated_at REAL NOT NULL,
                    expires_at REAL,
                    access_count INTEGER DEFAULT 0,
                    last_accessed_by TEXT,
                    last_accessed_at REAL,
                    dependencies TEXT DEFAULT '',
                    watchers TEXT DEFAULT '',
                    metadata_json TEXT DEFAULT '{}',
                    version INTEGER DEFAULT 1,
                    parent_id TEXT,
                    children_ids TEXT DEFAULT ''
                )
            ''')
            
            # Create indexes
            conn.execute('CREATE INDEX IF NOT EXISTS idx_key_scope ON context_items (key, scope)')
            conn.execute('CREATE INDEX IF NOT EXISTS idx_owner_agent ON context_items (owner_agent)')
            conn.execute('CREATE INDEX IF NOT EXISTS idx_expires_at ON context_items (expires_at)')
            conn.execute('CREATE INDEX IF NOT EXISTS idx_created_at ON context_items (created_at)')
    
    async def store(self, item: ContextItem) -> bool:
        """Store context item in SQLite."""
        def _store():
            with sqlite3.connect(str(self.db_path)) as conn:
                conn.execute('''
                    INSERT OR REPLACE INTO context_items (
                        id, key, value_json, context_type, scope, priority, access_level,
                        owner_agent, authorized_agents, tags, created_at, updated_at,
                        expires_at, access_count, last_accessed_by, last_accessed_at,
                        dependencies, watchers, metadata_json, version, parent_id, children_ids
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    item.id, item.key, json.dumps(item.value), item.context_type.value,
                    item.scope.value, item.priority.value, item.access_level.value,
                    item.owner_agent, ','.join(item.authorized_agents), ','.join(item.tags),
                    item.created_at.timestamp(), item.updated_at.timestamp(),
                    item.expires_at.timestamp() if item.expires_at else None,
                    item.access_count, item.last_accessed_by,
                    item.last_accessed_at.timestamp() if item.last_accessed_at else None,
                    ','.join(item.dependencies), ','.join(item.watchers),
                    json.dumps(item.metadata), item.version, item.parent_id,
                    ','.join(item.children_ids)
                ))
        
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor() as executor:
            await loop.run_in_executor(executor, _store)
        return True
    
    async def retrieve(self, key: str, scope: ContextScope) -> Optional[ContextItem]:
        """Retrieve context item from SQLite."""
        def _retrieve():
            with sqlite3.connect(str(self.db_path)) as conn:
                cursor = conn.execute(
                    'SELECT * FROM context_items WHERE key = ? AND scope = ?',
                    (key, scope.value)
                )
                row = cursor.fetchone()
                if row:
                    return self._row_to_item(row)
                return None
        
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor() as executor:
            return await loop.run_in_executor(executor, _retrieve)
    
    async def query(self, filters: Dict[str, Any]) -> List[ContextItem]:
        """Query context items with filters."""
        def _query():
            with sqlite3.connect(str(self.db_path)) as conn:
                where_clauses = []
                params = []
                
                if 'scope' in filters:
                    where_clauses.append('scope = ?')
                    params.append(filters['scope'].value if isinstance(filters['scope'], ContextScope) else filters['scope'])
                
                if 'owner_agent' in filters:
                    where_clauses.append('owner_agent = ?')
                    params.append(filters['owner_agent'])
                
                if 'context_type' in filters:
                    where_clauses.append('context_type = ?')
                    params.append(filters['context_type'].value if isinstance(filters['context_type'], ContextType) else filters['context_type'])
                
                if 'tag' in filters:
                    where_clauses.append('tags LIKE ?')
                    params.append(f'%{filters["tag"]}%')
                
                if 'created_after' in filters:
                    where_clauses.append('created_at > ?')
                    params.append(filters['created_after'].timestamp())
                
                query = 'SELECT * FROM context_items'
                if where_clauses:
                    query += ' WHERE ' + ' AND '.join(where_clauses)
                query += ' ORDER BY priority DESC, created_at DESC'
                
                cursor = conn.execute(query, params)
                return [self._row_to_item(row) for row in cursor.fetchall()]
        
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor() as executor:
            return await loop.run_in_executor(executor, _query)
    
    async def delete(self, key: str, scope: ContextScope) -> bool:
        """Delete context item from SQLite."""
        def _delete():
            with sqlite3.connect(str(self.db_path)) as conn:
                cursor = conn.execute(
                    'DELETE FROM context_items WHERE key = ? AND scope = ?',
                    (key, scope.value)
                )
                return cursor.rowcount > 0
        
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor() as executor:
            return await loop.run_in_executor(executor, _delete)
    
    async def cleanup_expired(self) -> int:
        """Remove expired context items."""
        def _cleanup():
            with sqlite3.connect(str(self.db_path)) as conn:
                now = time.time()
                cursor = conn.execute(
                    'DELETE FROM context_items WHERE expires_at IS NOT NULL AND expires_at < ?',
                    (now,)
                )
                return cursor.rowcount
        
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor() as executor:
            return await loop.run_in_executor(executor, _cleanup)
    
    def _row_to_item(self, row) -> ContextItem:
        """Convert database row to ContextItem."""
        return ContextItem(
            id=row[0],
            key=row[1],
            value=json.loads(row[2]),
            context_type=ContextType(row[3]),
            scope=ContextScope(row[4]),
            priority=ContextPriority(row[5]),
            access_level=ContextAccessLevel(row[6]),
            owner_agent=row[7],
            authorized_agents=set(row[8].split(',')) if row[8] else set(),
            tags=set(row[9].split(',')) if row[9] else set(),
            created_at=datetime.fromtimestamp(row[10]),
            updated_at=datetime.fromtimestamp(row[11]),
            expires_at=datetime.fromtimestamp(row[12]) if row[12] else None,
            access_count=row[13],
            last_accessed_by=row[14],
            last_accessed_at=datetime.fromtimestamp(row[15]) if row[15] else None,
            dependencies=set(row[16].split(',')) if row[16] else set(),
            watchers=set(row[17].split(',')) if row[17] else set(),
            metadata=json.loads(row[18]),
            version=row[19],
            parent_id=row[20],
            children_ids=set(row[21].split(',')) if row[21] else set()
        )

class RedisContextStorage(ContextStorage):
    """Redis-based context storage for distributed systems."""
    
    def __init__(self, redis_url: str = "redis://localhost:6379"):
        self.redis_client = redis.from_url(redis_url, decode_responses=True)
        self.key_prefix = "exxede:context:"
    
    async def store(self, item: ContextItem) -> bool:
        """Store context item in Redis."""
        key = f"{self.key_prefix}{item.scope.value}:{item.key}"
        value = json.dumps(asdict(item), default=str)
        
        # Store with expiration if specified
        if item.expires_at:
            ttl = int((item.expires_at - datetime.now()).total_seconds())
            if ttl > 0:
                self.redis_client.setex(key, ttl, value)
            else:
                return False  # Already expired
        else:
            self.redis_client.set(key, value)
        
        # Add to indexes
        self._update_indexes(item)
        return True
    
    async def retrieve(self, key: str, scope: ContextScope) -> Optional[ContextItem]:
        """Retrieve context item from Redis."""
        redis_key = f"{self.key_prefix}{scope.value}:{key}"
        value = self.redis_client.get(redis_key)
        
        if value:
            data = json.loads(value)
            return self._dict_to_item(data)
        return None
    
    async def query(self, filters: Dict[str, Any]) -> List[ContextItem]:
        """Query context items using Redis indexes."""
        # Simplified query using pattern matching
        pattern = f"{self.key_prefix}*"
        keys = self.redis_client.keys(pattern)
        
        items = []
        for key in keys:
            value = self.redis_client.get(key)
            if value:
                item = self._dict_to_item(json.loads(value))
                if self._matches_filters(item, filters):
                    items.append(item)
        
        # Sort by priority and creation time
        items.sort(key=lambda x: (x.priority.value, x.created_at), reverse=True)
        return items
    
    async def delete(self, key: str, scope: ContextScope) -> bool:
        """Delete context item from Redis."""
        redis_key = f"{self.key_prefix}{scope.value}:{key}"
        return self.redis_client.delete(redis_key) > 0
    
    async def cleanup_expired(self) -> int:
        """Redis handles expiration automatically."""
        return 0
    
    def _update_indexes(self, item: ContextItem):
        """Update Redis indexes for faster querying."""
        # Add to agent index
        agent_key = f"{self.key_prefix}index:agent:{item.owner_agent}"
        self.redis_client.sadd(agent_key, f"{item.scope.value}:{item.key}")
        
        # Add to type index
        type_key = f"{self.key_prefix}index:type:{item.context_type.value}"
        self.redis_client.sadd(type_key, f"{item.scope.value}:{item.key}")
    
    def _dict_to_item(self, data: Dict[str, Any]) -> ContextItem:
        """Convert dictionary to ContextItem."""
        # Handle datetime conversions
        if isinstance(data['created_at'], str):
            data['created_at'] = datetime.fromisoformat(data['created_at'])
        if isinstance(data['updated_at'], str):
            data['updated_at'] = datetime.fromisoformat(data['updated_at'])
        if data.get('expires_at') and isinstance(data['expires_at'], str):
            data['expires_at'] = datetime.fromisoformat(data['expires_at'])
        if data.get('last_accessed_at') and isinstance(data['last_accessed_at'], str):
            data['last_accessed_at'] = datetime.fromisoformat(data['last_accessed_at'])
        
        # Handle enum conversions
        data['context_type'] = ContextType(data['context_type'])
        data['scope'] = ContextScope(data['scope'])
        data['priority'] = ContextPriority(data['priority'])
        data['access_level'] = ContextAccessLevel(data['access_level'])
        
        # Handle set conversions
        for field in ['authorized_agents', 'tags', 'dependencies', 'watchers', 'children_ids']:
            if isinstance(data[field], list):
                data[field] = set(data[field])
        
        return ContextItem(**data)
    
    def _matches_filters(self, item: ContextItem, filters: Dict[str, Any]) -> bool:
        """Check if item matches query filters."""
        for key, value in filters.items():
            if key == 'scope' and item.scope != value:
                return False
            elif key == 'owner_agent' and item.owner_agent != value:
                return False
            elif key == 'context_type' and item.context_type != value:
                return False
            elif key == 'tag' and value not in item.tags:
                return False
            elif key == 'created_after' and item.created_at <= value:
                return False
        return True

class SharedContextSystem:
    """Enterprise-grade shared context system for agent communication."""
    
    def __init__(
        self,
        storage_backend: ContextStorage = None,
        enable_persistence: bool = True,
        data_dir: Path = None
    ):
        self.data_dir = data_dir or Path.home() / ".exxede" / "context"
        self.data_dir.mkdir(parents=True, exist_ok=True)
        
        # Storage backend
        if storage_backend:
            self.storage = storage_backend
        elif enable_persistence:
            self.storage = SQLiteContextStorage(self.data_dir / "context.db")
        else:
            self.storage = None  # Memory-only mode
        
        # In-memory cache for performance
        self.memory_cache = {}
        self.cache_lock = threading.RLock()
        
        # Subscriptions and event system
        self.subscriptions = defaultdict(list)
        self.event_queue = asyncio.Queue()
        self.event_handlers = []
        
        # Performance tracking
        self.access_stats = defaultdict(int)
        self.operation_times = deque(maxlen=1000)
        
        # Cleanup task
        self.cleanup_task = None
        
        # Logging
        self.logger = logging.getLogger(__name__)
    
    async def start(self):
        """Start the context system."""
        # Start periodic cleanup task
        self.cleanup_task = asyncio.create_task(self._periodic_cleanup())
        
        # Start event processing
        for _ in range(3):  # Multiple event processors
            asyncio.create_task(self._process_events())
        
        self.logger.info("Shared context system started")
    
    async def stop(self):
        """Stop the context system."""
        if self.cleanup_task:
            self.cleanup_task.cancel()
        
        self.logger.info("Shared context system stopped")
    
    async def set_context(
        self,
        key: str,
        value: Any,
        agent_id: str,
        context_type: ContextType = ContextType.DATA,
        scope: ContextScope = ContextScope.SESSION,
        priority: ContextPriority = ContextPriority.NORMAL,
        access_level: ContextAccessLevel = ContextAccessLevel.PUBLIC,
        tags: Set[str] = None,
        expires_in: Optional[timedelta] = None,
        dependencies: Set[str] = None,
        metadata: Dict[str, Any] = None
    ) -> str:
        """Set context value with comprehensive metadata."""
        start_time = time.time()
        
        # Create context item
        item_id = str(uuid.uuid4())
        expires_at = datetime.now() + expires_in if expires_in else None
        
        item = ContextItem(
            id=item_id,
            key=key,
            value=value,
            context_type=context_type,
            scope=scope,
            priority=priority,
            access_level=access_level,
            owner_agent=agent_id,
            tags=tags or set(),
            expires_at=expires_at,
            dependencies=dependencies or set(),
            metadata=metadata or {}
        )
        
        # Store in memory cache
        cache_key = f"{scope.value}:{key}"
        with self.cache_lock:
            self.memory_cache[cache_key] = item
        
        # Store in persistent backend
        if self.storage:
            await self.storage.store(item)
        
        # Record access stats
        self.access_stats['set_operations'] += 1
        self.operation_times.append(time.time() - start_time)
        
        # Emit event
        await self._emit_event(ContextEvent(
            event_id=str(uuid.uuid4()),
            event_type="created",
            context_id=item_id,
            agent_id=agent_id,
            details={"key": key, "scope": scope.value}
        ))
        
        self.logger.debug(f"Context set: {key} by {agent_id}")
        return item_id
    
    async def get_context(
        self,
        key: str,
        agent_id: str,
        scope: ContextScope = ContextScope.SESSION,
        default: Any = None
    ) -> Any:
        """Get context value with access control."""
        start_time = time.time()
        
        # Check memory cache first
        cache_key = f"{scope.value}:{key}"
        with self.cache_lock:
            if cache_key in self.memory_cache:
                item = self.memory_cache[cache_key]
            else:
                item = None
        
        # Fallback to persistent storage
        if not item and self.storage:
            item = await self.storage.retrieve(key, scope)
            if item:
                # Cache for future access
                with self.cache_lock:
                    self.memory_cache[cache_key] = item
        
        if not item:
            return default
        
        # Check access permissions
        if not self._check_access(item, agent_id):
            self.logger.warning(f"Access denied: {agent_id} tried to access {key}")
            return default
        
        # Check expiration
        if item.expires_at and datetime.now() > item.expires_at:
            await self.delete_context(key, agent_id, scope)
            return default
        
        # Update access metadata
        item.access_count += 1
        item.last_accessed_by = agent_id
        item.last_accessed_at = datetime.now()
        
        # Update in storage
        if self.storage:
            await self.storage.store(item)
        
        # Record stats
        self.access_stats['get_operations'] += 1
        self.operation_times.append(time.time() - start_time)
        
        # Emit event
        await self._emit_event(ContextEvent(
            event_id=str(uuid.uuid4()),
            event_type="accessed",
            context_id=item.id,
            agent_id=agent_id,
            details={"key": key, "scope": scope.value}
        ))
        
        return item.value
    
    async def query_context(
        self,
        agent_id: str,
        filters: Dict[str, Any] = None,
        limit: int = 100
    ) -> List[ContextItem]:
        """Query context items with filters."""
        filters = filters or {}
        
        # Query from storage
        if self.storage:
            items = await self.storage.query(filters)
        else:
            # Query from memory cache
            items = []
            with self.cache_lock:
                for item in self.memory_cache.values():
                    if self._matches_query(item, filters) and self._check_access(item, agent_id):
                        items.append(item)
        
        # Filter by access permissions
        accessible_items = [item for item in items if self._check_access(item, agent_id)]
        
        # Apply limit
        return accessible_items[:limit]
    
    async def delete_context(
        self,
        key: str,
        agent_id: str,
        scope: ContextScope = ContextScope.SESSION
    ) -> bool:
        """Delete context item with permission check."""
        # Get item to check permissions
        item = await self.storage.retrieve(key, scope) if self.storage else None
        cache_key = f"{scope.value}:{key}"
        
        with self.cache_lock:
            if cache_key in self.memory_cache:
                item = self.memory_cache[cache_key]
        
        if not item:
            return False
        
        # Check if agent has permission to delete
        if item.owner_agent != agent_id and item.access_level != ContextAccessLevel.PUBLIC:
            self.logger.warning(f"Delete denied: {agent_id} cannot delete {key}")
            return False
        
        # Remove from memory cache
        with self.cache_lock:
            self.memory_cache.pop(cache_key, None)
        
        # Remove from storage
        success = False
        if self.storage:
            success = await self.storage.delete(key, scope)
        
        # Emit event
        if success or not self.storage:
            await self._emit_event(ContextEvent(
                event_id=str(uuid.uuid4()),
                event_type="deleted",
                context_id=item.id,
                agent_id=agent_id,
                details={"key": key, "scope": scope.value}
            ))
        
        self.access_stats['delete_operations'] += 1
        return True
    
    async def subscribe(
        self,
        agent_id: str,
        pattern: str,
        callback: Callable,
        filters: Dict[str, Any] = None
    ) -> str:
        """Subscribe to context changes."""
        subscription = ContextSubscription(
            agent_id=agent_id,
            pattern=pattern,
            callback=callback,
            filters=filters or {}
        )
        
        subscription_id = str(uuid.uuid4())
        self.subscriptions[pattern].append((subscription_id, subscription))
        
        self.logger.info(f"Agent {agent_id} subscribed to pattern: {pattern}")
        return subscription_id
    
    async def unsubscribe(self, subscription_id: str) -> bool:
        """Unsubscribe from context changes."""
        for pattern, subscriptions in self.subscriptions.items():
            for i, (sub_id, subscription) in enumerate(subscriptions):
                if sub_id == subscription_id:
                    subscriptions.pop(i)
                    self.logger.info(f"Unsubscribed: {subscription_id}")
                    return True
        return False
    
    async def create_context_tree(
        self,
        root_key: str,
        agent_id: str,
        tree_data: Dict[str, Any],
        scope: ContextScope = ContextScope.SESSION
    ) -> List[str]:
        """Create hierarchical context structure."""
        created_ids = []
        
        async def create_node(key: str, value: Any, parent_id: str = None):
            if isinstance(value, dict) and not isinstance(value, str):
                # Create parent node
                node_id = await self.set_context(
                    key=key,
                    value={"type": "container", "children": list(value.keys())},
                    agent_id=agent_id,
                    context_type=ContextType.METADATA,
                    scope=scope
                )
                created_ids.append(node_id)
                
                # Create children
                for child_key, child_value in value.items():
                    full_child_key = f"{key}.{child_key}"
                    child_id = await create_node(full_child_key, child_value, node_id)
                    
                    # Update parent with child reference
                    parent_item = await self.storage.retrieve(key, scope) if self.storage else None
                    if parent_item:
                        parent_item.children_ids.add(child_id)
                        if self.storage:
                            await self.storage.store(parent_item)
                
                return node_id
            else:
                # Create leaf node
                node_id = await self.set_context(
                    key=key,
                    value=value,
                    agent_id=agent_id,
                    scope=scope,
                    metadata={"parent_id": parent_id} if parent_id else {}
                )
                created_ids.append(node_id)
                return node_id
        
        await create_node(root_key, tree_data)
        return created_ids
    
    async def get_agent_context_summary(self, agent_id: str) -> Dict[str, Any]:
        """Get comprehensive context summary for an agent."""
        # Query all accessible context
        items = await self.query_context(agent_id, limit=1000)
        
        # Organize by scope and type
        summary = {
            "total_items": len(items),
            "by_scope": defaultdict(int),
            "by_type": defaultdict(int),
            "owned_items": 0,
            "recent_activity": [],
            "top_accessed": []
        }
        
        for item in items:
            summary["by_scope"][item.scope.value] += 1
            summary["by_type"][item.context_type.value] += 1
            
            if item.owner_agent == agent_id:
                summary["owned_items"] += 1
            
            # Track recent activity
            if item.last_accessed_at and item.last_accessed_at > datetime.now() - timedelta(hours=24):
                summary["recent_activity"].append({
                    "key": item.key,
                    "accessed_at": item.last_accessed_at.isoformat(),
                    "access_count": item.access_count
                })
        
        # Sort recent activity
        summary["recent_activity"].sort(key=lambda x: x["accessed_at"], reverse=True)
        summary["recent_activity"] = summary["recent_activity"][:10]
        
        # Top accessed items
        items_with_access = [item for item in items if item.access_count > 0]
        items_with_access.sort(key=lambda x: x.access_count, reverse=True)
        summary["top_accessed"] = [
            {"key": item.key, "access_count": item.access_count}
            for item in items_with_access[:10]
        ]
        
        return summary
    
    def get_performance_metrics(self) -> Dict[str, Any]:
        """Get system performance metrics."""
        with self.cache_lock:
            cache_size = len(self.memory_cache)
        
        avg_operation_time = statistics.mean(self.operation_times) if self.operation_times else 0
        
        return {
            "cache_size": cache_size,
            "operation_stats": dict(self.access_stats),
            "avg_operation_time_ms": avg_operation_time * 1000,
            "total_operations": sum(self.access_stats.values()),
            "active_subscriptions": sum(len(subs) for subs in self.subscriptions.values())
        }
    
    async def export_context(
        self,
        agent_id: str,
        scope: ContextScope = None,
        format: str = "json"
    ) -> str:
        """Export context data for backup or migration."""
        filters = {}
        if scope:
            filters["scope"] = scope
        
        items = await self.query_context(agent_id, filters)
        
        # Convert to serializable format
        export_data = {
            "export_metadata": {
                "agent_id": agent_id,
                "exported_at": datetime.now().isoformat(),
                "total_items": len(items),
                "scope": scope.value if scope else "all"
            },
            "context_items": []
        }
        
        for item in items:
            item_dict = asdict(item)
            # Convert datetime objects to ISO strings
            for field in ['created_at', 'updated_at', 'expires_at', 'last_accessed_at']:
                if item_dict[field]:
                    item_dict[field] = item_dict[field].isoformat() if hasattr(item_dict[field], 'isoformat') else item_dict[field]
            
            # Convert sets to lists
            for field in ['authorized_agents', 'tags', 'dependencies', 'watchers', 'children_ids']:
                if isinstance(item_dict[field], set):
                    item_dict[field] = list(item_dict[field])
            
            export_data["context_items"].append(item_dict)
        
        if format == "json":
            return json.dumps(export_data, indent=2)
        elif format == "yaml":
            return yaml.dump(export_data, default_flow_style=False)
        else:
            raise ValueError(f"Unsupported export format: {format}")
    
    def _check_access(self, item: ContextItem, agent_id: str) -> bool:
        """Check if agent has access to context item."""
        if item.access_level == ContextAccessLevel.PUBLIC:
            return True
        elif item.access_level == ContextAccessLevel.PRIVATE:
            return item.owner_agent == agent_id
        elif item.access_level == ContextAccessLevel.RESTRICTED:
            return agent_id == item.owner_agent or agent_id in item.authorized_agents
        elif item.access_level == ContextAccessLevel.SYSTEM:
            return agent_id.startswith("SYSTEM_")
        return False
    
    def _matches_query(self, item: ContextItem, filters: Dict[str, Any]) -> bool:
        """Check if item matches query filters."""
        for key, value in filters.items():
            if key == 'scope' and item.scope != value:
                return False
            elif key == 'context_type' and item.context_type != value:
                return False
            elif key == 'owner_agent' and item.owner_agent != value:
                return False
            elif key == 'tag' and value not in item.tags:
                return False
            elif key == 'priority' and item.priority.value < value:
                return False
        return True
    
    async def _emit_event(self, event: ContextEvent):
        """Emit context event for subscribers."""
        await self.event_queue.put(event)
    
    async def _process_events(self):
        """Process context events and notify subscribers."""
        while True:
            try:
                event = await self.event_queue.get()
                
                # Find matching subscriptions
                for pattern, subscriptions in self.subscriptions.items():
                    if self._pattern_matches(pattern, event):
                        for sub_id, subscription in subscriptions:
                            if subscription.active:
                                try:
                                    if asyncio.iscoroutinefunction(subscription.callback):
                                        await subscription.callback(event)
                                    else:
                                        subscription.callback(event)
                                    subscription.trigger_count += 1
                                except Exception as e:
                                    self.logger.error(f"Subscription callback error: {e}")
                
            except Exception as e:
                self.logger.error(f"Event processing error: {e}")
    
    def _pattern_matches(self, pattern: str, event: ContextEvent) -> bool:
        """Check if event matches subscription pattern."""
        # Simple pattern matching (can be enhanced with regex)
        if pattern == "*":
            return True
        if pattern.startswith("type:"):
            return event.event_type == pattern[5:]
        if pattern.startswith("agent:"):
            return event.agent_id == pattern[6:]
        return pattern in event.details.get("key", "")
    
    async def _periodic_cleanup(self):
        """Periodic cleanup of expired context items."""
        while True:
            try:
                # Cleanup expired items
                if self.storage:
                    cleaned = await self.storage.cleanup_expired()
                    if cleaned > 0:
                        self.logger.info(f"Cleaned up {cleaned} expired context items")
                
                # Cleanup memory cache
                with self.cache_lock:
                    expired_keys = []
                    for key, item in self.memory_cache.items():
                        if item.expires_at and datetime.now() > item.expires_at:
                            expired_keys.append(key)
                    
                    for key in expired_keys:
                        del self.memory_cache[key]
                
                # Wait before next cleanup
                await asyncio.sleep(300)  # 5 minutes
                
            except Exception as e:
                self.logger.error(f"Cleanup error: {e}")
                await asyncio.sleep(60)  # Wait 1 minute on error


# Convenience functions for easy usage
async def create_shared_context(
    data_dir: Path = None,
    enable_redis: bool = False,
    redis_url: str = "redis://localhost:6379"
) -> SharedContextSystem:
    """Create and start shared context system."""
    storage = None
    
    if enable_redis:
        try:
            storage = RedisContextStorage(redis_url)
        except Exception as e:
            logging.warning(f"Redis unavailable, falling back to SQLite: {e}")
            storage = SQLiteContextStorage(data_dir / "context.db" if data_dir else Path.home() / ".exxede" / "context" / "context.db")
    else:
        storage = SQLiteContextStorage(data_dir / "context.db" if data_dir else Path.home() / ".exxede" / "context" / "context.db")
    
    context_system = SharedContextSystem(storage, enable_persistence=True, data_dir=data_dir)
    await context_system.start()
    return context_system


if __name__ == "__main__":
    async def main():
        """Demo of shared context system."""
        print("🌐 Shared Context System Demo")
        
        # Create context system
        context = await create_shared_context()
        
        try:
            # Set some context data
            await context.set_context(
                key="project_requirements",
                value={"platform": "mobile", "target_market": "Dominican Republic", "budget": 50000},
                agent_id="ARQ",
                context_type=ContextType.DATA,
                scope=ContextScope.PROJECT,
                tags={"project", "requirements"}
            )
            
            await context.set_context(
                key="design_guidelines",
                value={"colors": ["blue", "white", "red"], "style": "modern", "accessibility": True},
                agent_id="VEX",
                context_type=ContextType.INSIGHT,
                scope=ContextScope.PROJECT,
                tags={"design", "guidelines"}
            )
            
            # Query context
            project_context = await context.query_context(
                agent_id="SAGE",
                filters={"scope": ContextScope.PROJECT, "tag": "project"}
            )
            
            print(f"📊 Found {len(project_context)} project context items")
            
            # Get context by key
            requirements = await context.get_context(
                key="project_requirements",
                agent_id="SAGE",
                scope=ContextScope.PROJECT
            )
            
            print(f"💰 Project budget: ${requirements['budget']:,}")
            
            # Get agent summary
            summary = await context.get_agent_context_summary("ARQ")
            print(f"🤖 ARQ has access to {summary['total_items']} context items")
            
            # Performance metrics
            metrics = context.get_performance_metrics()
            print(f"⚡ Performance: {metrics['avg_operation_time_ms']:.2f}ms avg operation time")
            
        finally:
            await context.stop()
    
    asyncio.run(main())