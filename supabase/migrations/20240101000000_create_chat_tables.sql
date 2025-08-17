-- Task 5.1: Define chat_messages schema; insert user and assistant segments

-- Create chat_messages table for conversation persistence
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id TEXT NOT NULL,
    message_id TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    attachments JSONB,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '90 days'),
    
    -- Indexes for performance
    CONSTRAINT unique_message_id UNIQUE (message_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_id ON chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_chat_messages_expires_at ON chat_messages(expires_at);

-- Create conversations table for metadata
CREATE TABLE IF NOT EXISTS chat_conversations (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    message_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '90 days')
);

-- Create indexes for conversations
CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id ON chat_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_last_message_at ON chat_conversations(last_message_at);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_expires_at ON chat_conversations(expires_at);

-- Create chat_rate_limits table for rate limiting
CREATE TABLE IF NOT EXISTS chat_rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    window_start TIMESTAMP WITH TIME ZONE NOT NULL,
    window_end TIMESTAMP WITH TIME ZONE NOT NULL,
    request_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicate windows
    CONSTRAINT unique_user_window UNIQUE (user_id, window_start)
);

-- Create indexes for rate limits
CREATE INDEX IF NOT EXISTS idx_chat_rate_limits_user_id ON chat_rate_limits(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_rate_limits_window ON chat_rate_limits(window_start, window_end);

-- Enable Row Level Security
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rate_limits ENABLE ROW LEVEL SECURITY;

-- RLS Policies for chat_messages
CREATE POLICY "Users can view their own messages" ON chat_messages
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own messages" ON chat_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own messages" ON chat_messages
    FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for chat_conversations
CREATE POLICY "Users can view their own conversations" ON chat_conversations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own conversations" ON chat_conversations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conversations" ON chat_conversations
    FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for chat_rate_limits
CREATE POLICY "Users can view their own rate limits" ON chat_rate_limits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage rate limits" ON chat_rate_limits
    FOR ALL USING (auth.role() = 'service_role');

-- Function to update conversation metadata
CREATE OR REPLACE FUNCTION update_conversation_metadata()
RETURNS TRIGGER AS $$
BEGIN
    -- Update or insert conversation metadata
    INSERT INTO chat_conversations (id, user_id, last_message_at, message_count)
    VALUES (NEW.conversation_id, NEW.user_id, NEW.created_at, 1)
    ON CONFLICT (id) DO UPDATE SET
        last_message_at = NEW.created_at,
        message_count = chat_conversations.message_count + 1,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update conversation metadata when messages are inserted
CREATE TRIGGER update_conversation_on_message_insert
    AFTER INSERT ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_metadata();

-- Function for cleanup of expired messages (Task 5.3)
CREATE OR REPLACE FUNCTION cleanup_expired_chat_data()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Soft delete expired messages (mark as deleted)
    UPDATE chat_messages 
    SET metadata = jsonb_set(COALESCE(metadata, '{}'), '{deleted}', 'true')
    WHERE expires_at < NOW() 
    AND (metadata->>'deleted' IS NULL OR metadata->>'deleted' != 'true');
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Clean up expired conversations
    UPDATE chat_conversations 
    SET expires_at = NOW() - INTERVAL '1 day'
    WHERE expires_at < NOW();
    
    -- Clean up old rate limit records (older than 24 hours)
    DELETE FROM chat_rate_limits 
    WHERE window_end < NOW() - INTERVAL '24 hours';
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
CREATE TRIGGER update_chat_messages_updated_at
    BEFORE UPDATE ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_conversations_updated_at
    BEFORE UPDATE ON chat_conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_rate_limits_updated_at
    BEFORE UPDATE ON chat_rate_limits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
