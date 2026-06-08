import { MomentMatchStatus, MomentMatchType } from '@prisma/client';
import { MomentMatchWithRelations } from './matching-engine.repository';

export interface MomentParticipantDto {
  id: string;
  username: string;
  avatar_url: string | null;
}

export interface MomentMatchDto {
  id: string;
  matchType: MomentMatchType;
  status: MomentMatchStatus;
  user_a_id: string;
  user_b_id: string;
  user_a_friend_consent: boolean | null;
  user_b_friend_consent: boolean | null;
  scheduled_at: Date;
  expires_at: Date;
  conversation_id: string;
  group_id: string | null;
  group_name: string | null;
  participants: MomentParticipantDto[];
  writable: boolean;
}

export function serializeMomentMatch(
  match: MomentMatchWithRelations,
): MomentMatchDto {
  const now = new Date();
  const isWithinMomentWindow =
    match.scheduled_at.getTime() <= now.getTime() &&
    match.expires_at.getTime() > now.getTime();
  const writable = isWithinMomentWindow;

  return {
    id: match.id,
    matchType: match.match_type,
    status: match.status,
    user_a_id: match.user_a_id,
    user_b_id: match.user_b_id,
    user_a_friend_consent: match.user_a_friend_consent,
    user_b_friend_consent: match.user_b_friend_consent,
    scheduled_at: match.scheduled_at,
    expires_at: match.expires_at,
    conversation_id: match.conversation_id,
    group_id: match.group_id,
    group_name: match.group?.name ?? null,
    participants: [
      {
        id: match.user_a.id,
        username: match.user_a.username,
        avatar_url: match.user_a.avatar_url,
      },
      {
        id: match.user_b.id,
        username: match.user_b.username,
        avatar_url: match.user_b.avatar_url,
      },
    ],
    writable,
  };
}
