-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  subtitle TEXT NOT NULL,
  icon_type TEXT NOT NULL DEFAULT 'message',
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  action_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(user_id, is_read);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only read their own notifications
CREATE POLICY "Users can read own notifications" ON notifications
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can only update their own notifications
CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policy: Only service role can insert notifications
CREATE POLICY "Service role can insert notifications" ON notifications
  FOR INSERT
  WITH CHECK (true);

-- Insert sample notifications for testing
-- (Replace user_id with actual user IDs from your auth.users table)
-- INSERT INTO notifications (user_id, type, title, subtitle, icon_type)
-- VALUES
--   (auth.uid(), 'offer', 'New offer on your listing', 'Someone made an offer on your Toyota Corolla 2020', 'offer'),
--   (auth.uid(), 'message', 'New message received', 'Ahmad sent you a message about your iPhone 14 listing', 'message'),
--   (auth.uid(), 'favorite', 'Someone saved your ad', 'Your listing "2BHK Apartment Kabul" was saved by 3 people', 'favorite');
