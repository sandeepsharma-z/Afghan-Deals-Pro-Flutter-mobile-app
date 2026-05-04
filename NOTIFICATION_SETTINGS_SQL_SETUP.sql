-- Create notification_settings table
CREATE TABLE IF NOT EXISTS notification_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  push_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  new_messages BOOLEAN NOT NULL DEFAULT TRUE,
  new_offers BOOLEAN NOT NULL DEFAULT TRUE,
  price_drops BOOLEAN NOT NULL DEFAULT TRUE,
  saved_ads BOOLEAN NOT NULL DEFAULT FALSE,
  account_alerts BOOLEAN NOT NULL DEFAULT TRUE,
  promotions BOOLEAN NOT NULL DEFAULT FALSE,
  weekly_digest BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only read their own settings
CREATE POLICY "Users can read own settings" ON notification_settings
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can only update their own settings
CREATE POLICY "Users can update own settings" ON notification_settings
  FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own settings
CREATE POLICY "Users can insert own settings" ON notification_settings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_notification_settings_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-update
DROP TRIGGER IF EXISTS notification_settings_updated_at_trigger ON notification_settings;
CREATE TRIGGER notification_settings_updated_at_trigger
  BEFORE UPDATE ON notification_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_notification_settings_timestamp();
