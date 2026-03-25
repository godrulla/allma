export interface Message {
  id: string;
  conversationId: string;
  content: string;
  isUser: boolean;
  timestamp: Date;
  attachments?: Attachment[];
  emotion?: string;
  metadata?: MessageMetadata;
}

export interface Attachment {
  type: 'image' | 'audio' | 'file';
  url: string;
  thumbnail?: string;
  mimeType: string;
  size: number;
}

export interface MessageMetadata {
  edited?: boolean;
  editedAt?: Date;
  replyTo?: string;
  reactions?: Reaction[];
}

export interface Reaction {
  emoji: string;
  userId: string;
  timestamp: Date;
}

export interface Conversation {
  id: string;
  userId: string;
  characterId: string;
  messages: Message[];
  startedAt: Date;
  lastMessageAt: Date;
  summary?: string;
  topics?: string[];
  mood?: string;
  isActive: boolean;
}