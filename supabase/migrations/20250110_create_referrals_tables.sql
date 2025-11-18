-- Create referrals table
CREATE TABLE IF NOT EXISTS public.referrals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    code TEXT NOT NULL UNIQUE,
    successful_referrals INTEGER DEFAULT 0,
    earned_reward NUMERIC(10, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    CONSTRAINT referrals_user_id_unique UNIQUE (user_id),
    CONSTRAINT referrals_successful_referrals_check CHECK (successful_referrals >= 0),
    CONSTRAINT referrals_earned_reward_check CHECK (earned_reward >= 0)
);

-- Create referral_conversions table
CREATE TABLE IF NOT EXISTS public.referral_conversions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referral_code TEXT NOT NULL,
    referrer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    referred_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reward_amount NUMERIC(10, 2) NOT NULL,
    reward_redeemed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT referral_conversions_unique UNIQUE (referred_user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_referrals_user_id ON public.referrals(user_id);
CREATE INDEX IF NOT EXISTS idx_referrals_code ON public.referrals(code);
CREATE INDEX IF NOT EXISTS idx_referral_conversions_referrer_id ON public.referral_conversions(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referral_conversions_referred_user_id ON public.referral_conversions(referred_user_id);
CREATE INDEX IF NOT EXISTS idx_referral_conversions_code ON public.referral_conversions(referral_code);

-- Enable Row Level Security
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_conversions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for referrals table
CREATE POLICY "Users can view their own referral data"
    ON public.referrals
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own referral data"
    ON public.referrals
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own referral data"
    ON public.referrals
    FOR UPDATE
    USING (auth.uid() = user_id);

-- RLS Policies for referral_conversions table
CREATE POLICY "Users can view their own conversions (as referrer)"
    ON public.referral_conversions
    FOR SELECT
    USING (auth.uid() = referrer_id OR auth.uid() = referred_user_id);

CREATE POLICY "Anyone can insert conversions"
    ON public.referral_conversions
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Users can update conversions they referred"
    ON public.referral_conversions
    FOR UPDATE
    USING (auth.uid() = referrer_id);

-- Function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_referrals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function
CREATE TRIGGER set_referrals_updated_at
    BEFORE UPDATE ON public.referrals
    FOR EACH ROW
    EXECUTE FUNCTION update_referrals_updated_at();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON public.referrals TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.referral_conversions TO authenticated;
