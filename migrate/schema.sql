--
-- PostgreSQL database dump
--

-- Dumped from database version 13.5
-- Dumped by pg_dump version 13.6 (Ubuntu 13.6-0ubuntu0.21.10.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: engine_processing_type; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.engine_processing_type AS ENUM (
    'escalation',
    'heartbeat',
    'np_cycle',
    'rotation',
    'schedule',
    'status_update',
    'verify',
    'message',
    'cleanup',
    'metrics',
    'compat'
);


ALTER TYPE public.engine_processing_type OWNER TO goalert;

--
-- Name: enum_alert_log_event; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_alert_log_event AS ENUM (
    'created',
    'reopened',
    'status_changed',
    'assignment_changed',
    'escalated',
    'closed',
    'notification_sent',
    'response_received',
    'acknowledged',
    'policy_updated',
    'duplicate_suppressed',
    'escalation_request',
    'no_notification_sent'
);


ALTER TYPE public.enum_alert_log_event OWNER TO goalert;

--
-- Name: enum_alert_log_subject_type; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_alert_log_subject_type AS ENUM (
    'user',
    'integration_key',
    'heartbeat_monitor',
    'channel'
);


ALTER TYPE public.enum_alert_log_subject_type OWNER TO goalert;

--
-- Name: enum_alert_source; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_alert_source AS ENUM (
    'grafana',
    'manual',
    'generic',
    'email',
    'site24x7',
    'prometheusAlertmanager'
);


ALTER TYPE public.enum_alert_source OWNER TO goalert;

--
-- Name: enum_alert_status; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_alert_status AS ENUM (
    'triggered',
    'active',
    'closed'
);


ALTER TYPE public.enum_alert_status OWNER TO goalert;

--
-- Name: enum_heartbeat_state; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_heartbeat_state AS ENUM (
    'inactive',
    'healthy',
    'unhealthy'
);


ALTER TYPE public.enum_heartbeat_state OWNER TO goalert;

--
-- Name: enum_integration_keys_type; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_integration_keys_type AS ENUM (
    'grafana',
    'generic',
    'email',
    'site24x7',
    'prometheusAlertmanager'
);


ALTER TYPE public.enum_integration_keys_type OWNER TO goalert;

--
-- Name: enum_limit_type; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_limit_type AS ENUM (
    'notification_rules_per_user',
    'contact_methods_per_user',
    'ep_steps_per_policy',
    'ep_actions_per_step',
    'participants_per_rotation',
    'rules_per_schedule',
    'integration_keys_per_service',
    'unacked_alerts_per_service',
    'targets_per_schedule',
    'heartbeat_monitors_per_service',
    'user_overrides_per_schedule',
    'calendar_subscriptions_per_user'
);


ALTER TYPE public.enum_limit_type OWNER TO goalert;

--
-- Name: enum_notif_channel_type; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_notif_channel_type AS ENUM (
    'SLACK',
    'WEBHOOK'
);


ALTER TYPE public.enum_notif_channel_type OWNER TO goalert;

--
-- Name: enum_outgoing_messages_status; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_outgoing_messages_status AS ENUM (
    'pending',
    'sending',
    'queued_remotely',
    'sent',
    'delivered',
    'failed',
    'bundled'
);


ALTER TYPE public.enum_outgoing_messages_status OWNER TO goalert;

--
-- Name: enum_outgoing_messages_type; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_outgoing_messages_type AS ENUM (
    'alert_notification',
    'verification_message',
    'test_notification',
    'alert_status_update',
    'alert_notification_bundle',
    'alert_status_update_bundle',
    'schedule_on_call_notification'
);


ALTER TYPE public.enum_outgoing_messages_type OWNER TO goalert;

--
-- Name: enum_rotation_type; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_rotation_type AS ENUM (
    'weekly',
    'daily',
    'hourly'
);


ALTER TYPE public.enum_rotation_type OWNER TO goalert;

--
-- Name: enum_switchover_state; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_switchover_state AS ENUM (
    'idle',
    'in_progress',
    'use_next_db'
);


ALTER TYPE public.enum_switchover_state OWNER TO goalert;

--
-- Name: enum_throttle_type; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_throttle_type AS ENUM (
    'notifications',
    'notifications_2'
);


ALTER TYPE public.enum_throttle_type OWNER TO goalert;

--
-- Name: enum_user_contact_method_type; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_user_contact_method_type AS ENUM (
    'PUSH',
    'EMAIL',
    'VOICE',
    'SMS',
    'WEBHOOK',
    'SLACK_DM'
);


ALTER TYPE public.enum_user_contact_method_type OWNER TO goalert;

--
-- Name: enum_user_role; Type: TYPE; Schema: public; Owner: goalert
--

CREATE TYPE public.enum_user_role AS ENUM (
    'unknown',
    'user',
    'admin'
);


ALTER TYPE public.enum_user_role OWNER TO goalert;

--
-- Name: aquire_user_contact_method_lock(uuid, bigint, uuid); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.aquire_user_contact_method_lock(_client_id uuid, _alert_id bigint, _contact_method_id uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
        DECLARE
            lock_id UUID = gen_random_uuid();
        BEGIN
            DELETE FROM user_contact_method_locks WHERE alert_id = _alert_id
                AND contact_method_id = _contact_method_id
                AND (timestamp + '5 minutes'::interval) < now();

            INSERT INTO user_contact_method_locks (id, alert_id, contact_method_id, client_id) 
                VALUES (lock_id, _alert_id, _contact_method_id, _client_id)
                RETURNING id INTO lock_id;

            INSERT INTO sent_notifications (id, alert_id, contact_method_id, cycle_id, notification_rule_id)
			SELECT lock_id, _alert_id, _contact_method_id, cycle_id, notification_rule_id
			FROM needs_notification_sent n
			WHERE n.alert_id = _alert_id AND n.contact_method_id = _contact_method_id
			ON CONFLICT DO NOTHING;

            RETURN lock_id;
        END;
    $$;


ALTER FUNCTION public.aquire_user_contact_method_lock(_client_id uuid, _alert_id bigint, _contact_method_id uuid) OWNER TO goalert;

--
-- Name: escalate_alerts(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.escalate_alerts() RETURNS void
    LANGUAGE plpgsql
    AS $$
        BEGIN
            UPDATE alerts
            SET escalation_level = escalation_level + 1, last_escalation = now()
            FROM alert_escalation_policy_snapshots e
            WHERE (last_escalation + e.step_delay) < now()
                AND status = 'triggered'
                AND id = e.alert_id
                AND e.step_number = (escalation_level % e.step_max)
                AND (e.repeat = -1 OR (escalation_level+1) / e.step_max <= e.repeat);
        END;
    $$;


ALTER FUNCTION public.escalate_alerts() OWNER TO goalert;

--
-- Name: fn_advance_or_end_rot_on_part_del(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_advance_or_end_rot_on_part_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_part UUID;
    active_part UUID;
BEGIN

    SELECT rotation_participant_id
    INTO active_part
    FROM rotation_state
    WHERE rotation_id = OLD.rotation_id;

    IF active_part != OLD.id THEN
        RETURN OLD;
    END IF;

    IF OLD.rotation_id NOT IN (
       SELECT id FROM rotations
    ) THEN
        DELETE FROM rotation_state
        WHERE rotation_id = OLD.rotation_id;
    END IF;

    SELECT id
    INTO new_part
    FROM rotation_participants
    WHERE
        rotation_id = OLD.rotation_id AND
        id != OLD.id AND
        position IN (0, OLD.position+1)
    ORDER BY position DESC
    LIMIT 1;

     IF new_part ISNULL THEN
        DELETE FROM rotation_state
        WHERE rotation_id = OLD.rotation_id;
    ELSE
        UPDATE rotation_state
        SET rotation_participant_id = new_part
        WHERE rotation_id = OLD.rotation_id;
    END IF;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.fn_advance_or_end_rot_on_part_del() OWNER TO goalert;

--
-- Name: fn_clear_dedup_on_close(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_clear_dedup_on_close() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.dedup_key = NULL;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_clear_dedup_on_close() OWNER TO goalert;

--
-- Name: fn_clear_ep_state_on_alert_close(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_clear_ep_state_on_alert_close() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM escalation_policy_state
    WHERE alert_id = NEW.id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_clear_ep_state_on_alert_close() OWNER TO goalert;

--
-- Name: fn_clear_ep_state_on_svc_ep_change(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_clear_ep_state_on_svc_ep_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE escalation_policy_state
    SET
        escalation_policy_id = NEW.escalation_policy_id,
        escalation_policy_step_id = NULL,
        loop_count = 0,
        last_escalation = NULL,
        next_escalation = NULL,
        force_escalation = false,
        escalation_policy_step_number = 0
    WHERE service_id = NEW.id
    ;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_clear_ep_state_on_svc_ep_change() OWNER TO goalert;

--
-- Name: fn_clear_next_esc_on_alert_ack(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_clear_next_esc_on_alert_ack() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    UPDATE escalation_policy_state
    SET next_escalation = null
    WHERE alert_id = NEW.id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_clear_next_esc_on_alert_ack() OWNER TO goalert;

--
-- Name: fn_decr_ep_step_count_on_del(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_decr_ep_step_count_on_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE escalation_policies
    SET step_count = step_count - 1
    WHERE id = OLD.escalation_policy_id;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.fn_decr_ep_step_count_on_del() OWNER TO goalert;

--
-- Name: fn_decr_ep_step_number_on_delete(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_decr_ep_step_number_on_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    LOCK escalation_policy_steps IN EXCLUSIVE MODE;

    UPDATE escalation_policy_steps
    SET step_number = step_number - 1
    WHERE
        escalation_policy_id = OLD.escalation_policy_id AND
        step_number > OLD.step_number;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.fn_decr_ep_step_number_on_delete() OWNER TO goalert;

--
-- Name: fn_decr_part_count_on_del(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_decr_part_count_on_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE rotations
    SET participant_count = participant_count - 1
    WHERE id = OLD.rotation_id;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.fn_decr_part_count_on_del() OWNER TO goalert;

--
-- Name: fn_decr_rot_part_position_on_delete(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_decr_rot_part_position_on_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    LOCK rotation_participants IN EXCLUSIVE MODE;

    UPDATE rotation_participants
    SET position = position - 1
    WHERE
        rotation_id = OLD.rotation_id AND
        position > OLD.position;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.fn_decr_rot_part_position_on_delete() OWNER TO goalert;

--
-- Name: fn_disable_inserts(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_disable_inserts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'inserts are disabled on this table';
END;
$$;


ALTER FUNCTION public.fn_disable_inserts() OWNER TO goalert;

--
-- Name: fn_enforce_alert_limit(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_alert_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'unacked_alerts_per_service';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM alerts
    WHERE service_id = NEW.service_id AND "status" = 'triggered';

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='unacked_alerts_per_service_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_alert_limit() OWNER TO goalert;

--
-- Name: fn_enforce_calendar_subscriptions_per_user_limit(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_calendar_subscriptions_per_user_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'calendar_subscriptions_per_user';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM user_calendar_subscriptions
    WHERE user_id = NEW.user_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='calendar_subscriptions_per_user_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_calendar_subscriptions_per_user_limit() OWNER TO goalert;

--
-- Name: fn_enforce_contact_method_limit(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_contact_method_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'contact_methods_per_user';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM user_contact_methods
    WHERE user_id = NEW.user_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='contact_methods_per_user_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_contact_method_limit() OWNER TO goalert;

--
-- Name: fn_enforce_ep_step_action_limit(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_ep_step_action_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'ep_actions_per_step';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM escalation_policy_actions
    WHERE escalation_policy_step_id = NEW.escalation_policy_step_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='ep_actions_per_step_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_ep_step_action_limit() OWNER TO goalert;

--
-- Name: fn_enforce_ep_step_limit(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_ep_step_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'ep_steps_per_policy';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM escalation_policy_steps
    WHERE escalation_policy_id = NEW.escalation_policy_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='ep_steps_per_policy_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_ep_step_limit() OWNER TO goalert;

--
-- Name: fn_enforce_ep_step_number_no_gaps(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_ep_step_number_no_gaps() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_pos INT := -1;
    step_count INT := 0;
BEGIN
    IF NEW.escalation_policy_id != OLD.escalation_policy_id THEN
        RAISE 'must not change escalation_policy_id of existing step';
    END IF;

    SELECT max(step_number), count(*)
    INTO max_pos, step_count
    FROM escalation_policy_steps
    WHERE escalation_policy_id = NEW.escalation_policy_id;

    IF max_pos >= step_count THEN
        RAISE 'must not have gap in step_numbers';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_ep_step_number_no_gaps() OWNER TO goalert;

--
-- Name: fn_enforce_heartbeat_limit(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_heartbeat_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'heartbeat_monitors_per_service';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM heartbeat_monitors
    WHERE service_id = NEW.service_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='heartbeat_monitors_per_service_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_heartbeat_limit() OWNER TO goalert;

--
-- Name: fn_enforce_integration_key_limit(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_integration_key_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'integration_keys_per_service';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM integration_keys
    WHERE service_id = NEW.service_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='integration_keys_per_service_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_integration_key_limit() OWNER TO goalert;

--
-- Name: fn_enforce_notification_rule_limit(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_notification_rule_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'notification_rules_per_user';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM user_notification_rules
    WHERE user_id = NEW.user_id;

    IF max_count != -1 AND val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='notification_rules_per_user_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_notification_rule_limit() OWNER TO goalert;

--
-- Name: fn_enforce_rot_part_position_no_gaps(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_rot_part_position_no_gaps() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_pos INT := -1;
    part_count INT := 0;
BEGIN
    IF NEW.rotation_id != OLD.rotation_id THEN
        RAISE 'must not change rotation_id of existing participant';
    END IF;

    SELECT max(position), count(*)
    INTO max_pos, part_count
    FROM rotation_participants
    WHERE rotation_id = NEW.rotation_id;

    IF max_pos >= part_count THEN
        RAISE 'must not have gap in participant positions';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_rot_part_position_no_gaps() OWNER TO goalert;

--
-- Name: fn_enforce_rotation_participant_limit(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_rotation_participant_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'participants_per_rotation';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM rotation_participants
    WHERE rotation_id = NEW.rotation_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='participants_per_rotation_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_rotation_participant_limit() OWNER TO goalert;

--
-- Name: fn_enforce_schedule_rule_limit(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_schedule_rule_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'rules_per_schedule';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM schedule_rules
    WHERE schedule_id = NEW.schedule_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='rules_per_schedule_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_schedule_rule_limit() OWNER TO goalert;

--
-- Name: fn_enforce_schedule_target_limit(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_schedule_target_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'targets_per_schedule';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM (
        SELECT DISTINCT tgt_user_id, tgt_rotation_id
        FROM schedule_rules
        WHERE schedule_id = NEW.schedule_id
    ) as tmp;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='targets_per_schedule_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_schedule_target_limit() OWNER TO goalert;

--
-- Name: fn_enforce_status_update_same_user(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_status_update_same_user() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    _cm_user_id UUID;
BEGIN
    IF NEW.alert_status_log_contact_method_id ISNULL THEN
        RETURN NEW;
    END IF;

    SELECT INTO _cm_user_id user_id
    FROM user_contact_methods
    WHERE id = NEW.alert_status_log_contact_method_id;

    IF NEW.id != _cm_user_id THEN
        RAISE 'wrong user_id' USING ERRCODE='check_violation', CONSTRAINT='alert_status_user_id_match';
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_status_update_same_user() OWNER TO goalert;

--
-- Name: fn_enforce_user_overide_no_conflict(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_user_overide_no_conflict() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    conflict UUID := NULL;
BEGIN
    EXECUTE 'LOCK user_overrides IN EXCLUSIVE MODE';

    SELECT id INTO conflict
    FROM user_overrides
    WHERE
        id != NEW.id AND
        tgt_schedule_id = NEW.tgt_schedule_id AND
        (
            add_user_id in (NEW.remove_user_id, NEW.add_user_id) OR
            remove_user_id in (NEW.remove_user_id, NEW.add_user_id)
        ) AND
        (start_time, end_time) OVERLAPS (NEW.start_time, NEW.end_time)
    LIMIT 1;
  
    IF conflict NOTNULL THEN
        RAISE 'override conflict' USING ERRCODE='check_violation', CONSTRAINT='user_override_no_conflict_allowed', HINT='CONFLICTING_ID='||conflict::text;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_user_overide_no_conflict() OWNER TO goalert;

--
-- Name: fn_enforce_user_override_schedule_limit(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_enforce_user_override_schedule_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'user_overrides_per_schedule';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM user_overrides
    WHERE
        tgt_schedule_id = NEW.tgt_schedule_id AND
        end_time > now();

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='user_overrides_per_schedule_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_user_override_schedule_limit() OWNER TO goalert;

--
-- Name: fn_inc_ep_step_number_on_insert(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_inc_ep_step_number_on_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    LOCK escalation_policy_steps IN EXCLUSIVE MODE;

    SELECT count(*)
    INTO NEW.step_number
    FROM escalation_policy_steps
    WHERE escalation_policy_id = NEW.escalation_policy_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_inc_ep_step_number_on_insert() OWNER TO goalert;

--
-- Name: fn_inc_rot_part_position_on_insert(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_inc_rot_part_position_on_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    LOCK rotation_participants IN EXCLUSIVE MODE;

    SELECT count(*)
    INTO NEW.position
    FROM rotation_participants
    WHERE rotation_id = NEW.rotation_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_inc_rot_part_position_on_insert() OWNER TO goalert;

--
-- Name: fn_incr_ep_step_count_on_add(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_incr_ep_step_count_on_add() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE escalation_policies
    SET step_count = step_count + 1
    WHERE id = NEW.escalation_policy_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_incr_ep_step_count_on_add() OWNER TO goalert;

--
-- Name: fn_incr_part_count_on_add(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_incr_part_count_on_add() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE rotations
    SET participant_count = participant_count + 1
    WHERE id = NEW.rotation_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_incr_part_count_on_add() OWNER TO goalert;

--
-- Name: fn_insert_basic_user(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_insert_basic_user() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    INSERT INTO auth_subjects (provider_id, subject_id, user_id)
    VALUES ('basic', NEW.username, NEW.user_id)
    ON CONFLICT (provider_id, subject_id) DO UPDATE
    SET user_id = NEW.user_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_insert_basic_user() OWNER TO goalert;

--
-- Name: fn_insert_ep_state_on_alert_insert(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_insert_ep_state_on_alert_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    INSERT INTO escalation_policy_state (alert_id, service_id, escalation_policy_id)
    SELECT NEW.id, NEW.service_id, svc.escalation_policy_id
    FROM services svc
    JOIN escalation_policies ep ON ep.id = svc.escalation_policy_id AND ep.step_count > 0
    WHERE svc.id = NEW.service_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_insert_ep_state_on_alert_insert() OWNER TO goalert;

--
-- Name: fn_insert_ep_state_on_step_insert(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_insert_ep_state_on_step_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    INSERT INTO escalation_policy_state (alert_id, service_id, escalation_policy_id)
    SELECT a.id, a.service_id, NEW.escalation_policy_id
    FROM alerts a
    JOIN services svc ON
        svc.id = a.service_id AND
        svc.escalation_policy_id = NEW.escalation_policy_id
    WHERE a.status != 'closed';

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_insert_ep_state_on_step_insert() OWNER TO goalert;

--
-- Name: fn_insert_user_last_alert_log(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_insert_user_last_alert_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    INSERT INTO user_last_alert_log (user_id, alert_id, log_id, next_log_id)
    VALUES (NEW.sub_user_id, NEW.alert_id, NEW.id, NEW.id)
    ON CONFLICT DO NOTHING;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_insert_user_last_alert_log() OWNER TO goalert;

--
-- Name: fn_lock_svc_on_force_escalation(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_lock_svc_on_force_escalation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    -- lock service first
    PERFORM 1
    FROM services svc
    WHERE svc.id = NEW.service_id
    FOR UPDATE;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_lock_svc_on_force_escalation() OWNER TO goalert;

--
-- Name: fn_notification_rule_same_user(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_notification_rule_same_user() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    _cm_user_id UUID;
BEGIN
    SELECT INTO _cm_user_id user_id
    FROM user_contact_methods
    WHERE id = NEW.contact_method_id;

    IF NEW.user_id != _cm_user_id THEN
        RAISE 'wrong user_id' USING ERRCODE='check_violation', CONSTRAINT='notification_rule_user_id_match';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_notification_rule_same_user() OWNER TO goalert;

--
-- Name: fn_notify_config_refresh(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_notify_config_refresh() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        NOTIFY "/goalert/config-refresh";
        RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.fn_notify_config_refresh() OWNER TO goalert;

--
-- Name: fn_prevent_reopen(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_prevent_reopen() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF OLD.status = 'closed' THEN
            RAISE EXCEPTION 'cannot change status of closed alert';
        END IF;
        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.fn_prevent_reopen() OWNER TO goalert;

--
-- Name: fn_set_ep_state_svc_id_on_insert(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_set_ep_state_svc_id_on_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    SELECT service_id INTO NEW.service_id
    FROM alerts
    WHERE id = NEW.alert_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_set_ep_state_svc_id_on_insert() OWNER TO goalert;

--
-- Name: fn_set_rot_state_pos_on_active_change(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_set_rot_state_pos_on_active_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    SELECT position INTO NEW.position
    FROM rotation_participants
    WHERE id = NEW.rotation_participant_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_set_rot_state_pos_on_active_change() OWNER TO goalert;

--
-- Name: fn_set_rot_state_pos_on_part_reorder(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_set_rot_state_pos_on_part_reorder() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE rotation_state
    SET position = NEW.position
    WHERE rotation_participant_id = NEW.id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_set_rot_state_pos_on_part_reorder() OWNER TO goalert;

--
-- Name: fn_start_rotation_on_first_part_add(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_start_rotation_on_first_part_add() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    first_part UUID;
BEGIN
    SELECT id
    INTO first_part
    FROM rotation_participants
    WHERE rotation_id = NEW.rotation_id AND position = 0;

    INSERT INTO rotation_state (
        rotation_id, rotation_participant_id, shift_start
    ) VALUES (
        NEW.rotation_id, first_part, now()
    ) ON CONFLICT DO NOTHING;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_start_rotation_on_first_part_add() OWNER TO goalert;

--
-- Name: fn_trig_alert_on_force_escalation(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_trig_alert_on_force_escalation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    UPDATE alerts
    SET "status" = 'triggered'
    WHERE id = NEW.alert_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_trig_alert_on_force_escalation() OWNER TO goalert;

--
-- Name: fn_update_user_last_alert_log(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.fn_update_user_last_alert_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    UPDATE user_last_alert_log last
    SET next_log_id = NEW.id
    WHERE
        last.alert_id = NEW.alert_id AND
        NEW.id > last.next_log_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_update_user_last_alert_log() OWNER TO goalert;

--
-- Name: move_escalation_policy_step(uuid, integer); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.move_escalation_policy_step(_id uuid, _new_pos integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
  DECLARE
    _old_pos INT;
    _epid UUID;
  BEGIN
    SELECT step_number, escalation_policy_id into _old_pos, _epid FROM escalation_policy_steps WHERE id = _id;
    IF _old_pos > _new_pos THEN
      UPDATE escalation_policy_steps
      SET step_number = step_number + 1
      WHERE escalation_policy_id = _epid
        AND step_number < _old_pos
        AND step_number >= _new_pos;
    ELSE
      UPDATE escalation_policy_steps
      SET step_number = step_number - 1
      WHERE escalation_policy_id = _epid
        AND step_number > _old_pos
        AND step_number <= _new_pos;
    END IF;
    UPDATE escalation_policy_steps
    SET step_number = _new_pos
    WHERE id = _id;
  END;
  $$;


ALTER FUNCTION public.move_escalation_policy_step(_id uuid, _new_pos integer) OWNER TO goalert;

--
-- Name: move_rotation_position(uuid, integer); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.move_rotation_position(_id uuid, _new_pos integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE
        _old_pos INT;
        _rid UUID;
    BEGIN
        SELECT position,rotation_id into _old_pos, _rid FROM rotation_participants WHERE id = _id;
        IF _old_pos > _new_pos THEN
            UPDATE rotation_participants SET position = position + 1 WHERE rotation_id = _rid AND position < _old_pos AND position >= _new_pos;
        ELSE
            UPDATE rotation_participants SET position = position - 1 WHERE rotation_id = _rid AND position > _old_pos AND position <= _new_pos;
        END IF;
        UPDATE rotation_participants SET position = _new_pos WHERE id = _id;
    END;
    $$;


ALTER FUNCTION public.move_rotation_position(_id uuid, _new_pos integer) OWNER TO goalert;

--
-- Name: release_user_contact_method_lock(uuid, uuid, boolean); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.release_user_contact_method_lock(_client_id uuid, _id uuid, success boolean) RETURNS void
    LANGUAGE plpgsql
    AS $$
        BEGIN
            DELETE FROM user_contact_method_locks WHERE id = _id AND client_id = _client_id;
            IF success
            THEN
                UPDATE sent_notifications SET sent_at = now() WHERE id = _id;
            ELSE
                DELETE FROM sent_notifications WHERE id = _id;
            END IF;
        END;
    $$;


ALTER FUNCTION public.release_user_contact_method_lock(_client_id uuid, _id uuid, success boolean) OWNER TO goalert;

--
-- Name: remove_rotation_participant(uuid); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.remove_rotation_participant(_id uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
    DECLARE
        _old_pos INT;
        _rid UUID;
    BEGIN
        SELECT position,rotation_id into _old_pos, _rid FROM rotation_participants WHERE id = _id;
        DELETE FROM rotation_participants WHERE id = _id;
        UPDATE rotation_participants SET position = position - 1 WHERE rotation_id = _rid AND position > _old_pos;
        RETURN _rid;
    END;
    $$;


ALTER FUNCTION public.remove_rotation_participant(_id uuid) OWNER TO goalert;

--
-- Name: update_notification_cycles(); Type: FUNCTION; Schema: public; Owner: goalert
--

CREATE FUNCTION public.update_notification_cycles() RETURNS void
    LANGUAGE plpgsql
    AS $$
        BEGIN
			INSERT INTO user_notification_cycles (user_id, alert_id, escalation_level)
			SELECT user_id, alert_id, escalation_level
			FROM on_call_alert_users
			WHERE status = 'triggered'
                AND user_id IS NOT NULL
			ON CONFLICT DO NOTHING;

			UPDATE user_notification_cycles c
			SET escalation_level = a.escalation_level
			FROM
				alerts a,
				user_notification_cycle_state s
			WHERE a.id = c.alert_id
				AND s.user_id = c.user_id
				AND s.alert_id = c.alert_id;

			DELETE FROM user_notification_cycles c
			WHERE (
				SELECT count(notification_rule_id)
				FROM user_notification_cycle_state s
				WHERE s.alert_id = c.alert_id AND s.user_id = c.user_id
				LIMIT 1
			) = 0
				AND c.escalation_level != (SELECT escalation_level FROM alerts WHERE id = c.alert_id);

        END;
    $$;


ALTER FUNCTION public.update_notification_cycles() OWNER TO goalert;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alert_logs; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.alert_logs (
    id bigint NOT NULL,
    alert_id bigint,
    "timestamp" timestamp with time zone DEFAULT now(),
    event public.enum_alert_log_event NOT NULL,
    message text NOT NULL,
    sub_type public.enum_alert_log_subject_type,
    sub_user_id uuid,
    sub_integration_key_id uuid,
    sub_classifier text DEFAULT ''::text NOT NULL,
    meta json,
    sub_hb_monitor_id uuid,
    sub_channel_id uuid
);


ALTER TABLE public.alert_logs OWNER TO goalert;

--
-- Name: alert_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.alert_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alert_logs_id_seq OWNER TO goalert;

--
-- Name: alert_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.alert_logs_id_seq OWNED BY public.alert_logs.id;


--
-- Name: alert_metrics; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.alert_metrics (
    id bigint NOT NULL,
    alert_id bigint NOT NULL,
    service_id uuid NOT NULL,
    time_to_ack interval,
    time_to_close interval,
    escalated boolean DEFAULT false NOT NULL,
    closed_at timestamp with time zone NOT NULL
);


ALTER TABLE public.alert_metrics OWNER TO goalert;

--
-- Name: alert_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.alert_metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alert_metrics_id_seq OWNER TO goalert;

--
-- Name: alert_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.alert_metrics_id_seq OWNED BY public.alert_metrics.id;


--
-- Name: alert_status_subscriptions; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.alert_status_subscriptions (
    id bigint NOT NULL,
    channel_id uuid,
    contact_method_id uuid,
    alert_id bigint NOT NULL,
    last_alert_status public.enum_alert_status NOT NULL,
    CONSTRAINT alert_status_subscriptions_check CHECK (((channel_id IS NULL) <> (contact_method_id IS NULL)))
);


ALTER TABLE public.alert_status_subscriptions OWNER TO goalert;

--
-- Name: alert_status_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.alert_status_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alert_status_subscriptions_id_seq OWNER TO goalert;

--
-- Name: alert_status_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.alert_status_subscriptions_id_seq OWNED BY public.alert_status_subscriptions.id;


--
-- Name: alerts; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.alerts (
    id bigint NOT NULL,
    service_id uuid,
    source public.enum_alert_source DEFAULT 'manual'::public.enum_alert_source NOT NULL,
    status public.enum_alert_status DEFAULT 'triggered'::public.enum_alert_status NOT NULL,
    escalation_level integer DEFAULT 0 NOT NULL,
    last_escalation timestamp with time zone DEFAULT now(),
    last_processed timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    dedup_key text,
    summary text NOT NULL,
    details text DEFAULT ''::text NOT NULL,
    CONSTRAINT dedup_key_only_for_open_alerts CHECK (((status = 'closed'::public.enum_alert_status) = (dedup_key IS NULL)))
);


ALTER TABLE public.alerts OWNER TO goalert;

--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alerts_id_seq OWNER TO goalert;

--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.alerts_id_seq OWNED BY public.alerts.id;


--
-- Name: auth_basic_users; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.auth_basic_users (
    user_id uuid NOT NULL,
    username text NOT NULL,
    password_hash text NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE public.auth_basic_users OWNER TO goalert;

--
-- Name: auth_basic_users_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.auth_basic_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_basic_users_id_seq OWNER TO goalert;

--
-- Name: auth_basic_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.auth_basic_users_id_seq OWNED BY public.auth_basic_users.id;


--
-- Name: auth_link_requests; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.auth_link_requests (
    id uuid NOT NULL,
    provider_id text NOT NULL,
    subject_id text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE public.auth_link_requests OWNER TO goalert;

--
-- Name: auth_nonce; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.auth_nonce (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.auth_nonce OWNER TO goalert;

--
-- Name: auth_subjects; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.auth_subjects (
    provider_id text NOT NULL,
    subject_id text NOT NULL,
    user_id uuid NOT NULL,
    id bigint NOT NULL,
    cm_id uuid
)
WITH (fillfactor='80');


ALTER TABLE public.auth_subjects OWNER TO goalert;

--
-- Name: auth_subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.auth_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_subjects_id_seq OWNER TO goalert;

--
-- Name: auth_subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.auth_subjects_id_seq OWNED BY public.auth_subjects.id;


--
-- Name: auth_user_sessions; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.auth_user_sessions (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_agent text DEFAULT ''::text NOT NULL,
    user_id uuid,
    last_access_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.auth_user_sessions OWNER TO goalert;

--
-- Name: config; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.config (
    id integer NOT NULL,
    schema integer NOT NULL,
    data bytea NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.config OWNER TO goalert;

--
-- Name: config_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.config_id_seq OWNER TO goalert;

--
-- Name: config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.config_id_seq OWNED BY public.config.id;


--
-- Name: config_limits; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.config_limits (
    id public.enum_limit_type NOT NULL,
    max integer DEFAULT '-1'::integer NOT NULL
);


ALTER TABLE public.config_limits OWNER TO goalert;

--
-- Name: engine_processing_versions; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.engine_processing_versions (
    type_id public.engine_processing_type NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    state jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE public.engine_processing_versions OWNER TO goalert;

--
-- Name: ep_step_on_call_users; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.ep_step_on_call_users (
    user_id uuid NOT NULL,
    ep_step_id uuid NOT NULL,
    start_time timestamp with time zone DEFAULT now() NOT NULL,
    end_time timestamp with time zone,
    id bigint NOT NULL
);


ALTER TABLE public.ep_step_on_call_users OWNER TO goalert;

--
-- Name: ep_step_on_call_users_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.ep_step_on_call_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ep_step_on_call_users_id_seq OWNER TO goalert;

--
-- Name: ep_step_on_call_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.ep_step_on_call_users_id_seq OWNED BY public.ep_step_on_call_users.id;


--
-- Name: escalation_policies; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.escalation_policies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    repeat integer DEFAULT 0 NOT NULL,
    step_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.escalation_policies OWNER TO goalert;

--
-- Name: escalation_policy_actions; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.escalation_policy_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    escalation_policy_step_id uuid NOT NULL,
    user_id uuid,
    schedule_id uuid,
    rotation_id uuid,
    channel_id uuid,
    CONSTRAINT epa_there_can_only_be_one CHECK (((((
CASE
    WHEN (user_id IS NOT NULL) THEN 1
    ELSE 0
END +
CASE
    WHEN (schedule_id IS NOT NULL) THEN 1
    ELSE 0
END) +
CASE
    WHEN (rotation_id IS NOT NULL) THEN 1
    ELSE 0
END) +
CASE
    WHEN (channel_id IS NOT NULL) THEN 1
    ELSE 0
END) = 1))
);


ALTER TABLE public.escalation_policy_actions OWNER TO goalert;

--
-- Name: escalation_policy_state; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.escalation_policy_state (
    escalation_policy_id uuid NOT NULL,
    escalation_policy_step_id uuid,
    escalation_policy_step_number integer DEFAULT 0 NOT NULL,
    alert_id bigint NOT NULL,
    last_escalation timestamp with time zone,
    loop_count integer DEFAULT 0 NOT NULL,
    force_escalation boolean DEFAULT false NOT NULL,
    service_id uuid NOT NULL,
    next_escalation timestamp with time zone,
    id bigint NOT NULL
)
WITH (fillfactor='85');


ALTER TABLE public.escalation_policy_state OWNER TO goalert;

--
-- Name: escalation_policy_state_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.escalation_policy_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.escalation_policy_state_id_seq OWNER TO goalert;

--
-- Name: escalation_policy_state_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.escalation_policy_state_id_seq OWNED BY public.escalation_policy_state.id;


--
-- Name: escalation_policy_steps; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.escalation_policy_steps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    delay integer DEFAULT 1 NOT NULL,
    step_number integer DEFAULT '-1'::integer NOT NULL,
    escalation_policy_id uuid NOT NULL
);


ALTER TABLE public.escalation_policy_steps OWNER TO goalert;

--
-- Name: gorp_migrations; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.gorp_migrations (
    id text NOT NULL,
    applied_at timestamp with time zone
);


ALTER TABLE public.gorp_migrations OWNER TO goalert;

--
-- Name: heartbeat_monitors; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.heartbeat_monitors (
    id uuid NOT NULL,
    name text NOT NULL,
    service_id uuid NOT NULL,
    heartbeat_interval interval NOT NULL,
    last_state public.enum_heartbeat_state DEFAULT 'inactive'::public.enum_heartbeat_state NOT NULL,
    last_heartbeat timestamp with time zone
);


ALTER TABLE public.heartbeat_monitors OWNER TO goalert;

--
-- Name: incident_number_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.incident_number_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.incident_number_seq OWNER TO goalert;

--
-- Name: integration_keys; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.integration_keys (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    type public.enum_integration_keys_type NOT NULL,
    service_id uuid NOT NULL
);


ALTER TABLE public.integration_keys OWNER TO goalert;

--
-- Name: keyring; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.keyring (
    id text NOT NULL,
    verification_keys bytea NOT NULL,
    signing_key bytea NOT NULL,
    next_key bytea NOT NULL,
    next_rotation timestamp with time zone,
    rotation_count bigint NOT NULL
);


ALTER TABLE public.keyring OWNER TO goalert;

--
-- Name: labels; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.labels (
    id bigint NOT NULL,
    tgt_service_id uuid NOT NULL,
    key text NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.labels OWNER TO goalert;

--
-- Name: labels_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.labels_id_seq OWNER TO goalert;

--
-- Name: labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.labels_id_seq OWNED BY public.labels.id;


--
-- Name: notification_channels; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.notification_channels (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    type public.enum_notif_channel_type NOT NULL,
    name text NOT NULL,
    value text NOT NULL,
    meta jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE public.notification_channels OWNER TO goalert;

--
-- Name: notification_policy_cycles; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.notification_policy_cycles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    alert_id integer NOT NULL,
    repeat_count integer DEFAULT 0 NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    checked boolean DEFAULT true NOT NULL,
    last_tick timestamp with time zone
)
WITH (fillfactor='65');


ALTER TABLE public.notification_policy_cycles OWNER TO goalert;

--
-- Name: outgoing_messages; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.outgoing_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    message_type public.enum_outgoing_messages_type NOT NULL,
    contact_method_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_status public.enum_outgoing_messages_status DEFAULT 'pending'::public.enum_outgoing_messages_status NOT NULL,
    last_status_at timestamp with time zone DEFAULT now(),
    status_details text DEFAULT ''::text NOT NULL,
    fired_at timestamp with time zone,
    sent_at timestamp with time zone,
    retry_count integer DEFAULT 0 NOT NULL,
    next_retry_at timestamp with time zone,
    sending_deadline timestamp with time zone,
    user_id uuid,
    alert_id bigint,
    cycle_id uuid,
    service_id uuid,
    escalation_policy_id uuid,
    alert_log_id bigint,
    user_verification_code_id uuid,
    provider_msg_id text,
    provider_seq integer DEFAULT 0 NOT NULL,
    channel_id uuid,
    status_alert_ids bigint[],
    schedule_id uuid,
    src_value text,
    CONSTRAINT om_alert_svc_ep_ids CHECK (((message_type <> 'alert_notification'::public.enum_outgoing_messages_type) OR ((alert_id IS NOT NULL) AND (service_id IS NOT NULL) AND (escalation_policy_id IS NOT NULL)))),
    CONSTRAINT om_no_status_bundles CHECK (((message_type <> 'alert_status_update_bundle'::public.enum_outgoing_messages_type) OR (last_status <> 'pending'::public.enum_outgoing_messages_status))),
    CONSTRAINT om_pending_no_fired_no_sent CHECK (((last_status <> 'pending'::public.enum_outgoing_messages_status) OR ((fired_at IS NULL) AND (sent_at IS NULL)))),
    CONSTRAINT om_processed_no_fired_sent CHECK (((last_status = ANY (ARRAY['pending'::public.enum_outgoing_messages_status, 'sending'::public.enum_outgoing_messages_status, 'failed'::public.enum_outgoing_messages_status, 'bundled'::public.enum_outgoing_messages_status])) OR ((fired_at IS NULL) AND (sent_at IS NOT NULL)))),
    CONSTRAINT om_sending_deadline_reqd CHECK (((last_status <> 'sending'::public.enum_outgoing_messages_status) OR (sending_deadline IS NOT NULL))),
    CONSTRAINT om_sending_fired_no_sent CHECK (((last_status <> 'sending'::public.enum_outgoing_messages_status) OR ((fired_at IS NOT NULL) AND (sent_at IS NULL)))),
    CONSTRAINT om_status_alert_ids CHECK (((message_type <> 'alert_status_update_bundle'::public.enum_outgoing_messages_type) OR (status_alert_ids IS NOT NULL))),
    CONSTRAINT om_status_update_log_id CHECK (((message_type <> 'alert_status_update'::public.enum_outgoing_messages_type) OR (alert_log_id IS NOT NULL))),
    CONSTRAINT om_user_cm_or_channel CHECK ((((user_id IS NOT NULL) AND (contact_method_id IS NOT NULL) AND (channel_id IS NULL)) OR ((channel_id IS NOT NULL) AND (contact_method_id IS NULL) AND (user_id IS NULL)))),
    CONSTRAINT verify_needs_id CHECK (((message_type <> 'verification_message'::public.enum_outgoing_messages_type) OR (user_verification_code_id IS NOT NULL)))
)
WITH (fillfactor='85');


ALTER TABLE public.outgoing_messages OWNER TO goalert;

--
-- Name: region_ids; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.region_ids (
    name text NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.region_ids OWNER TO goalert;

--
-- Name: region_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.region_ids_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.region_ids_id_seq OWNER TO goalert;

--
-- Name: region_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.region_ids_id_seq OWNED BY public.region_ids.id;


--
-- Name: rotation_participants; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.rotation_participants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    rotation_id uuid NOT NULL,
    "position" integer NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.rotation_participants OWNER TO goalert;

--
-- Name: rotation_state; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.rotation_state (
    rotation_id uuid NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    rotation_participant_id uuid NOT NULL,
    shift_start timestamp with time zone NOT NULL,
    id bigint NOT NULL,
    version integer DEFAULT 2 NOT NULL
);


ALTER TABLE public.rotation_state OWNER TO goalert;

--
-- Name: rotation_state_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.rotation_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rotation_state_id_seq OWNER TO goalert;

--
-- Name: rotation_state_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.rotation_state_id_seq OWNED BY public.rotation_state.id;


--
-- Name: rotations; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.rotations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    type public.enum_rotation_type NOT NULL,
    start_time timestamp with time zone DEFAULT now() NOT NULL,
    shift_length bigint DEFAULT 1 NOT NULL,
    time_zone text NOT NULL,
    last_processed timestamp with time zone,
    participant_count integer DEFAULT 0 NOT NULL,
    CONSTRAINT rotations_shift_length_check CHECK ((shift_length > 0))
);


ALTER TABLE public.rotations OWNER TO goalert;

--
-- Name: schedule_data; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.schedule_data (
    schedule_id uuid NOT NULL,
    last_cleanup_at timestamp with time zone,
    data jsonb NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE public.schedule_data OWNER TO goalert;

--
-- Name: schedule_data_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.schedule_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.schedule_data_id_seq OWNER TO goalert;

--
-- Name: schedule_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.schedule_data_id_seq OWNED BY public.schedule_data.id;


--
-- Name: schedule_on_call_users; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.schedule_on_call_users (
    schedule_id uuid NOT NULL,
    start_time timestamp with time zone DEFAULT now() NOT NULL,
    end_time timestamp with time zone,
    user_id uuid NOT NULL,
    id bigint NOT NULL,
    CONSTRAINT schedule_on_call_users_check CHECK (((end_time IS NULL) OR (end_time > start_time)))
);


ALTER TABLE public.schedule_on_call_users OWNER TO goalert;

--
-- Name: schedule_on_call_users_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.schedule_on_call_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.schedule_on_call_users_id_seq OWNER TO goalert;

--
-- Name: schedule_on_call_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.schedule_on_call_users_id_seq OWNED BY public.schedule_on_call_users.id;


--
-- Name: schedule_rules; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.schedule_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    schedule_id uuid NOT NULL,
    sunday boolean DEFAULT true NOT NULL,
    monday boolean DEFAULT true NOT NULL,
    tuesday boolean DEFAULT true NOT NULL,
    wednesday boolean DEFAULT true NOT NULL,
    thursday boolean DEFAULT true NOT NULL,
    friday boolean DEFAULT true NOT NULL,
    saturday boolean DEFAULT true NOT NULL,
    start_time time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    end_time time without time zone DEFAULT '23:59:59'::time without time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tgt_user_id uuid,
    tgt_rotation_id uuid,
    is_active boolean DEFAULT false NOT NULL,
    CONSTRAINT schedule_rules_check CHECK ((((tgt_user_id IS NULL) AND (tgt_rotation_id IS NOT NULL)) OR ((tgt_user_id IS NOT NULL) AND (tgt_rotation_id IS NULL))))
);


ALTER TABLE public.schedule_rules OWNER TO goalert;

--
-- Name: schedules; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.schedules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    time_zone text NOT NULL,
    last_processed timestamp with time zone
);


ALTER TABLE public.schedules OWNER TO goalert;

--
-- Name: services; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.services (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    escalation_policy_id uuid NOT NULL,
    maintenance_expires_at timestamp with time zone
);


ALTER TABLE public.services OWNER TO goalert;

--
-- Name: switchover_log; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.switchover_log (
    id bigint NOT NULL,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL,
    data jsonb NOT NULL
);


ALTER TABLE public.switchover_log OWNER TO goalert;

--
-- Name: switchover_state; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.switchover_state (
    ok boolean NOT NULL,
    current_state public.enum_switchover_state NOT NULL,
    db_id uuid DEFAULT gen_random_uuid() NOT NULL,
    CONSTRAINT switchover_state_ok_check CHECK (ok)
);


ALTER TABLE public.switchover_state OWNER TO goalert;

--
-- Name: twilio_sms_callbacks; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.twilio_sms_callbacks (
    phone_number text NOT NULL,
    callback_id uuid NOT NULL,
    code integer NOT NULL,
    id bigint NOT NULL,
    sent_at timestamp with time zone DEFAULT now() NOT NULL,
    alert_id bigint,
    service_id uuid
);


ALTER TABLE public.twilio_sms_callbacks OWNER TO goalert;

--
-- Name: twilio_sms_callbacks_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.twilio_sms_callbacks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.twilio_sms_callbacks_id_seq OWNER TO goalert;

--
-- Name: twilio_sms_callbacks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.twilio_sms_callbacks_id_seq OWNED BY public.twilio_sms_callbacks.id;


--
-- Name: twilio_sms_errors; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.twilio_sms_errors (
    phone_number text NOT NULL,
    error_message text NOT NULL,
    outgoing boolean NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE public.twilio_sms_errors OWNER TO goalert;

--
-- Name: twilio_sms_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.twilio_sms_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.twilio_sms_errors_id_seq OWNER TO goalert;

--
-- Name: twilio_sms_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.twilio_sms_errors_id_seq OWNED BY public.twilio_sms_errors.id;


--
-- Name: twilio_voice_errors; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.twilio_voice_errors (
    phone_number text NOT NULL,
    error_message text NOT NULL,
    outgoing boolean NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE public.twilio_voice_errors OWNER TO goalert;

--
-- Name: twilio_voice_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.twilio_voice_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.twilio_voice_errors_id_seq OWNER TO goalert;

--
-- Name: twilio_voice_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.twilio_voice_errors_id_seq OWNED BY public.twilio_voice_errors.id;


--
-- Name: user_calendar_subscriptions; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.user_calendar_subscriptions (
    id uuid NOT NULL,
    name text NOT NULL,
    user_id uuid NOT NULL,
    last_access timestamp with time zone,
    last_update timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    disabled boolean DEFAULT false NOT NULL,
    schedule_id uuid NOT NULL,
    config jsonb NOT NULL
);


ALTER TABLE public.user_calendar_subscriptions OWNER TO goalert;

--
-- Name: user_contact_methods; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.user_contact_methods (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    type public.enum_user_contact_method_type NOT NULL,
    value text NOT NULL,
    disabled boolean DEFAULT false NOT NULL,
    user_id uuid NOT NULL,
    last_test_verify_at timestamp with time zone,
    metadata jsonb,
    enable_status_updates boolean DEFAULT false NOT NULL
);


ALTER TABLE public.user_contact_methods OWNER TO goalert;

--
-- Name: user_favorites; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.user_favorites (
    user_id uuid NOT NULL,
    tgt_service_id uuid,
    id bigint NOT NULL,
    tgt_rotation_id uuid,
    tgt_schedule_id uuid,
    tgt_escalation_policy_id uuid,
    tgt_user_id uuid
);


ALTER TABLE public.user_favorites OWNER TO goalert;

--
-- Name: user_favorites_id_seq; Type: SEQUENCE; Schema: public; Owner: goalert
--

CREATE SEQUENCE public.user_favorites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_favorites_id_seq OWNER TO goalert;

--
-- Name: user_favorites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: goalert
--

ALTER SEQUENCE public.user_favorites_id_seq OWNED BY public.user_favorites.id;


--
-- Name: user_notification_rules; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.user_notification_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    delay_minutes integer DEFAULT 0 NOT NULL,
    contact_method_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.user_notification_rules OWNER TO goalert;

--
-- Name: user_overrides; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.user_overrides (
    id uuid NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    add_user_id uuid,
    remove_user_id uuid,
    tgt_schedule_id uuid NOT NULL,
    CONSTRAINT user_overrides_check CHECK ((end_time > start_time)),
    CONSTRAINT user_overrides_check1 CHECK ((COALESCE(add_user_id, remove_user_id) IS NOT NULL)),
    CONSTRAINT user_overrides_check2 CHECK ((add_user_id <> remove_user_id))
);


ALTER TABLE public.user_overrides OWNER TO goalert;

--
-- Name: user_slack_data; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.user_slack_data (
    id uuid NOT NULL,
    access_token text NOT NULL
);


ALTER TABLE public.user_slack_data OWNER TO goalert;

--
-- Name: user_verification_codes; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.user_verification_codes (
    id uuid NOT NULL,
    code integer NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    contact_method_id uuid NOT NULL,
    sent boolean DEFAULT false NOT NULL
);


ALTER TABLE public.user_verification_codes OWNER TO goalert;

--
-- Name: users; Type: TABLE; Schema: public; Owner: goalert
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    bio text DEFAULT ''::text NOT NULL,
    email text DEFAULT ''::text NOT NULL,
    role public.enum_user_role DEFAULT 'unknown'::public.enum_user_role NOT NULL,
    name text NOT NULL,
    avatar_url text DEFAULT ''::text NOT NULL,
    alert_status_log_contact_method_id uuid
);


ALTER TABLE public.users OWNER TO goalert;

--
-- Name: alert_logs id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alert_logs ALTER COLUMN id SET DEFAULT nextval('public.alert_logs_id_seq'::regclass);


--
-- Name: alert_metrics id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alert_metrics ALTER COLUMN id SET DEFAULT nextval('public.alert_metrics_id_seq'::regclass);


--
-- Name: alert_status_subscriptions id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alert_status_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.alert_status_subscriptions_id_seq'::regclass);


--
-- Name: alerts id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alerts ALTER COLUMN id SET DEFAULT nextval('public.alerts_id_seq'::regclass);


--
-- Name: auth_basic_users id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_basic_users ALTER COLUMN id SET DEFAULT nextval('public.auth_basic_users_id_seq'::regclass);


--
-- Name: auth_subjects id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_subjects ALTER COLUMN id SET DEFAULT nextval('public.auth_subjects_id_seq'::regclass);


--
-- Name: config id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.config ALTER COLUMN id SET DEFAULT nextval('public.config_id_seq'::regclass);


--
-- Name: ep_step_on_call_users id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.ep_step_on_call_users ALTER COLUMN id SET DEFAULT nextval('public.ep_step_on_call_users_id_seq'::regclass);


--
-- Name: escalation_policy_state id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_state ALTER COLUMN id SET DEFAULT nextval('public.escalation_policy_state_id_seq'::regclass);


--
-- Name: labels id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.labels ALTER COLUMN id SET DEFAULT nextval('public.labels_id_seq'::regclass);


--
-- Name: region_ids id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.region_ids ALTER COLUMN id SET DEFAULT nextval('public.region_ids_id_seq'::regclass);


--
-- Name: rotation_state id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.rotation_state ALTER COLUMN id SET DEFAULT nextval('public.rotation_state_id_seq'::regclass);


--
-- Name: schedule_data id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedule_data ALTER COLUMN id SET DEFAULT nextval('public.schedule_data_id_seq'::regclass);


--
-- Name: schedule_on_call_users id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedule_on_call_users ALTER COLUMN id SET DEFAULT nextval('public.schedule_on_call_users_id_seq'::regclass);


--
-- Name: twilio_sms_callbacks id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.twilio_sms_callbacks ALTER COLUMN id SET DEFAULT nextval('public.twilio_sms_callbacks_id_seq'::regclass);


--
-- Name: twilio_sms_errors id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.twilio_sms_errors ALTER COLUMN id SET DEFAULT nextval('public.twilio_sms_errors_id_seq'::regclass);


--
-- Name: twilio_voice_errors id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.twilio_voice_errors ALTER COLUMN id SET DEFAULT nextval('public.twilio_voice_errors_id_seq'::regclass);


--
-- Name: user_favorites id; Type: DEFAULT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_favorites ALTER COLUMN id SET DEFAULT nextval('public.user_favorites_id_seq'::regclass);


--
-- Name: alert_logs alert_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alert_logs
    ADD CONSTRAINT alert_logs_pkey PRIMARY KEY (id);


--
-- Name: alert_metrics alert_metrics_id_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alert_metrics
    ADD CONSTRAINT alert_metrics_id_key UNIQUE (id);


--
-- Name: alert_metrics alert_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alert_metrics
    ADD CONSTRAINT alert_metrics_pkey PRIMARY KEY (alert_id);


--
-- Name: alert_status_subscriptions alert_status_subscriptions_channel_id_contact_method_id_ale_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alert_status_subscriptions
    ADD CONSTRAINT alert_status_subscriptions_channel_id_contact_method_id_ale_key UNIQUE (channel_id, contact_method_id, alert_id);


--
-- Name: alert_status_subscriptions alert_status_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alert_status_subscriptions
    ADD CONSTRAINT alert_status_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: auth_basic_users auth_basic_users_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_basic_users
    ADD CONSTRAINT auth_basic_users_pkey PRIMARY KEY (user_id);


--
-- Name: auth_basic_users auth_basic_users_uniq_id; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_basic_users
    ADD CONSTRAINT auth_basic_users_uniq_id UNIQUE (id);


--
-- Name: auth_basic_users auth_basic_users_username_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_basic_users
    ADD CONSTRAINT auth_basic_users_username_key UNIQUE (username);


--
-- Name: auth_link_requests auth_link_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_link_requests
    ADD CONSTRAINT auth_link_requests_pkey PRIMARY KEY (id);


--
-- Name: auth_nonce auth_nonce_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_nonce
    ADD CONSTRAINT auth_nonce_pkey PRIMARY KEY (id);


--
-- Name: auth_subjects auth_subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_subjects
    ADD CONSTRAINT auth_subjects_pkey PRIMARY KEY (provider_id, subject_id);


--
-- Name: auth_subjects auth_subjects_uniq_id; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_subjects
    ADD CONSTRAINT auth_subjects_uniq_id UNIQUE (id);


--
-- Name: auth_user_sessions auth_user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_user_sessions
    ADD CONSTRAINT auth_user_sessions_pkey PRIMARY KEY (id);


--
-- Name: config_limits config_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.config_limits
    ADD CONSTRAINT config_limits_pkey PRIMARY KEY (id);


--
-- Name: config config_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.config
    ADD CONSTRAINT config_pkey PRIMARY KEY (id);


--
-- Name: engine_processing_versions engine_processing_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.engine_processing_versions
    ADD CONSTRAINT engine_processing_versions_pkey PRIMARY KEY (type_id);


--
-- Name: ep_step_on_call_users ep_step_on_call_users_uniq_id; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.ep_step_on_call_users
    ADD CONSTRAINT ep_step_on_call_users_uniq_id UNIQUE (id);


--
-- Name: escalation_policy_actions epa_no_duplicate_channels; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT epa_no_duplicate_channels UNIQUE (escalation_policy_step_id, channel_id);


--
-- Name: escalation_policy_actions epa_no_duplicate_rotations; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT epa_no_duplicate_rotations UNIQUE (escalation_policy_step_id, rotation_id);


--
-- Name: escalation_policy_actions epa_no_duplicate_schedules; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT epa_no_duplicate_schedules UNIQUE (escalation_policy_step_id, schedule_id);


--
-- Name: escalation_policy_actions epa_no_duplicate_users; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT epa_no_duplicate_users UNIQUE (escalation_policy_step_id, user_id);


--
-- Name: escalation_policies escalation_policies_name_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policies
    ADD CONSTRAINT escalation_policies_name_key UNIQUE (name);


--
-- Name: escalation_policies escalation_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policies
    ADD CONSTRAINT escalation_policies_pkey PRIMARY KEY (id);


--
-- Name: escalation_policy_actions escalation_policy_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT escalation_policy_actions_pkey PRIMARY KEY (id);


--
-- Name: escalation_policy_state escalation_policy_state_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT escalation_policy_state_pkey PRIMARY KEY (alert_id);


--
-- Name: escalation_policy_state escalation_policy_state_uniq_id; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT escalation_policy_state_uniq_id UNIQUE (id);


--
-- Name: escalation_policy_steps escalation_policy_steps_escalation_policy_id_step_number_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_steps
    ADD CONSTRAINT escalation_policy_steps_escalation_policy_id_step_number_key UNIQUE (escalation_policy_id, step_number) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: escalation_policy_steps escalation_policy_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_steps
    ADD CONSTRAINT escalation_policy_steps_pkey PRIMARY KEY (id);


--
-- Name: users goalert_user_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT goalert_user_pkey PRIMARY KEY (id);


--
-- Name: gorp_migrations gorp_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.gorp_migrations
    ADD CONSTRAINT gorp_migrations_pkey PRIMARY KEY (id);


--
-- Name: heartbeat_monitors heartbeat_monitors_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.heartbeat_monitors
    ADD CONSTRAINT heartbeat_monitors_pkey PRIMARY KEY (id);


--
-- Name: integration_keys integration_keys_name_service_id_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.integration_keys
    ADD CONSTRAINT integration_keys_name_service_id_key UNIQUE (name, service_id);


--
-- Name: integration_keys integration_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.integration_keys
    ADD CONSTRAINT integration_keys_pkey PRIMARY KEY (id);


--
-- Name: keyring keyring_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.keyring
    ADD CONSTRAINT keyring_pkey PRIMARY KEY (id);


--
-- Name: labels labels_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT labels_pkey PRIMARY KEY (id);


--
-- Name: labels labels_tgt_service_id_key_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT labels_tgt_service_id_key_key UNIQUE (tgt_service_id, key);


--
-- Name: notification_channels notification_channels_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.notification_channels
    ADD CONSTRAINT notification_channels_pkey PRIMARY KEY (id);


--
-- Name: notification_policy_cycles notification_policy_cycles_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.notification_policy_cycles
    ADD CONSTRAINT notification_policy_cycles_pkey PRIMARY KEY (id);


--
-- Name: outgoing_messages outgoing_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_pkey PRIMARY KEY (id);


--
-- Name: region_ids region_ids_id_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.region_ids
    ADD CONSTRAINT region_ids_id_key UNIQUE (id);


--
-- Name: region_ids region_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.region_ids
    ADD CONSTRAINT region_ids_pkey PRIMARY KEY (name);


--
-- Name: rotation_participants rotation_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.rotation_participants
    ADD CONSTRAINT rotation_participants_pkey PRIMARY KEY (id);


--
-- Name: rotation_participants rotation_participants_rotation_id_position_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.rotation_participants
    ADD CONSTRAINT rotation_participants_rotation_id_position_key UNIQUE (rotation_id, "position") DEFERRABLE INITIALLY DEFERRED;


--
-- Name: rotation_state rotation_state_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.rotation_state
    ADD CONSTRAINT rotation_state_pkey PRIMARY KEY (rotation_id);


--
-- Name: rotation_state rotation_state_uniq_id; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.rotation_state
    ADD CONSTRAINT rotation_state_uniq_id UNIQUE (id);


--
-- Name: rotations rotations_name_unique; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.rotations
    ADD CONSTRAINT rotations_name_unique UNIQUE (name);


--
-- Name: rotations rotations_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.rotations
    ADD CONSTRAINT rotations_pkey PRIMARY KEY (id);


--
-- Name: schedule_data schedule_data_id_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedule_data
    ADD CONSTRAINT schedule_data_id_key UNIQUE (id);


--
-- Name: schedule_data schedule_data_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedule_data
    ADD CONSTRAINT schedule_data_pkey PRIMARY KEY (schedule_id);


--
-- Name: schedule_on_call_users schedule_on_call_users_uniq_id; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedule_on_call_users
    ADD CONSTRAINT schedule_on_call_users_uniq_id UNIQUE (id);


--
-- Name: schedule_rules schedule_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedule_rules
    ADD CONSTRAINT schedule_rules_pkey PRIMARY KEY (id);


--
-- Name: schedules schedules_name_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedules
    ADD CONSTRAINT schedules_name_key UNIQUE (name);


--
-- Name: schedules schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedules
    ADD CONSTRAINT schedules_pkey PRIMARY KEY (id);


--
-- Name: services services_name_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_name_key UNIQUE (name);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: services svc_ep_uniq; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT svc_ep_uniq UNIQUE (id, escalation_policy_id);


--
-- Name: switchover_log switchover_log_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.switchover_log
    ADD CONSTRAINT switchover_log_pkey PRIMARY KEY (id);


--
-- Name: switchover_state switchover_state_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.switchover_state
    ADD CONSTRAINT switchover_state_pkey PRIMARY KEY (ok);


--
-- Name: twilio_sms_callbacks twilio_sms_callbacks_uniq_id; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.twilio_sms_callbacks
    ADD CONSTRAINT twilio_sms_callbacks_uniq_id UNIQUE (id);


--
-- Name: twilio_sms_errors twilio_sms_errors_uniq_id; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.twilio_sms_errors
    ADD CONSTRAINT twilio_sms_errors_uniq_id UNIQUE (id);


--
-- Name: twilio_voice_errors twilio_voice_errors_uniq_id; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.twilio_voice_errors
    ADD CONSTRAINT twilio_voice_errors_uniq_id UNIQUE (id);


--
-- Name: user_calendar_subscriptions user_calendar_subscriptions_name_schedule_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_calendar_subscriptions
    ADD CONSTRAINT user_calendar_subscriptions_name_schedule_id_user_id_key UNIQUE (name, schedule_id, user_id);


--
-- Name: user_calendar_subscriptions user_calendar_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_calendar_subscriptions
    ADD CONSTRAINT user_calendar_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: user_contact_methods user_contact_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_contact_methods
    ADD CONSTRAINT user_contact_methods_pkey PRIMARY KEY (id);


--
-- Name: user_contact_methods user_contact_methods_type_value_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_contact_methods
    ADD CONSTRAINT user_contact_methods_type_value_key UNIQUE (type, value);


--
-- Name: user_favorites user_favorites_uniq_id; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_uniq_id UNIQUE (id);


--
-- Name: user_favorites user_favorites_user_id_tgt_escalation_policy_id_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_user_id_tgt_escalation_policy_id_key UNIQUE (user_id, tgt_escalation_policy_id);


--
-- Name: user_favorites user_favorites_user_id_tgt_rotation_id_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_user_id_tgt_rotation_id_key UNIQUE (user_id, tgt_rotation_id);


--
-- Name: user_favorites user_favorites_user_id_tgt_schedule_id_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_user_id_tgt_schedule_id_key UNIQUE (user_id, tgt_schedule_id);


--
-- Name: user_favorites user_favorites_user_id_tgt_service_id_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_user_id_tgt_service_id_key UNIQUE (user_id, tgt_service_id);


--
-- Name: user_favorites user_favorites_user_id_tgt_user_id_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_user_id_tgt_user_id_key UNIQUE (user_id, tgt_user_id);


--
-- Name: user_notification_rules user_notification_rules_contact_method_id_delay_minutes_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_notification_rules
    ADD CONSTRAINT user_notification_rules_contact_method_id_delay_minutes_key UNIQUE (contact_method_id, delay_minutes);


--
-- Name: user_notification_rules user_notification_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_notification_rules
    ADD CONSTRAINT user_notification_rules_pkey PRIMARY KEY (id);


--
-- Name: user_overrides user_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_overrides
    ADD CONSTRAINT user_overrides_pkey PRIMARY KEY (id);


--
-- Name: user_slack_data user_slack_data_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_slack_data
    ADD CONSTRAINT user_slack_data_pkey PRIMARY KEY (id);


--
-- Name: user_verification_codes user_verification_codes_contact_method_id_key; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_verification_codes
    ADD CONSTRAINT user_verification_codes_contact_method_id_key UNIQUE (contact_method_id);


--
-- Name: user_verification_codes user_verification_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_verification_codes
    ADD CONSTRAINT user_verification_codes_pkey PRIMARY KEY (id);


--
-- Name: alert_metrics_closed_date_idx; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX alert_metrics_closed_date_idx ON public.alert_metrics USING btree (date(timezone('UTC'::text, closed_at)));


--
-- Name: escalation_policies_name; Type: INDEX; Schema: public; Owner: goalert
--

CREATE UNIQUE INDEX escalation_policies_name ON public.escalation_policies USING btree (lower(name));


--
-- Name: escalation_policy_state_next_escalation_force_escalation_idx; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX escalation_policy_state_next_escalation_force_escalation_idx ON public.escalation_policy_state USING btree (next_escalation, force_escalation);


--
-- Name: heartbeat_monitor_name_service_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE UNIQUE INDEX heartbeat_monitor_name_service_id ON public.heartbeat_monitors USING btree (lower(name), service_id);


--
-- Name: idx_alert_cleanup; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_alert_cleanup ON public.alerts USING btree (id, created_at) WHERE (status = 'closed'::public.enum_alert_status);


--
-- Name: idx_alert_logs_alert_event; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_alert_logs_alert_event ON public.alert_logs USING btree (alert_id, event);


--
-- Name: idx_alert_logs_alert_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_alert_logs_alert_id ON public.alert_logs USING btree (alert_id);


--
-- Name: idx_alert_logs_channel_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_alert_logs_channel_id ON public.alert_logs USING btree (sub_channel_id);


--
-- Name: idx_alert_logs_hb_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_alert_logs_hb_id ON public.alert_logs USING btree (sub_hb_monitor_id);


--
-- Name: idx_alert_logs_int_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_alert_logs_int_id ON public.alert_logs USING btree (sub_integration_key_id);


--
-- Name: idx_alert_logs_user_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_alert_logs_user_id ON public.alert_logs USING btree (sub_user_id);


--
-- Name: idx_alert_service_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_alert_service_id ON public.alerts USING btree (service_id);


--
-- Name: idx_closed_events; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_closed_events ON public.alert_logs USING btree ("timestamp") WHERE (event = 'closed'::public.enum_alert_log_event);


--
-- Name: idx_contact_method_users; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_contact_method_users ON public.user_contact_methods USING btree (user_id);


--
-- Name: idx_dedup_alerts; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_dedup_alerts ON public.alerts USING btree (dedup_key);


--
-- Name: idx_ep_action_steps; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_ep_action_steps ON public.escalation_policy_actions USING btree (escalation_policy_step_id);


--
-- Name: idx_ep_step_on_call; Type: INDEX; Schema: public; Owner: goalert
--

CREATE UNIQUE INDEX idx_ep_step_on_call ON public.ep_step_on_call_users USING btree (user_id, ep_step_id) WHERE (end_time IS NULL);


--
-- Name: idx_ep_step_policies; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_ep_step_policies ON public.escalation_policy_steps USING btree (escalation_policy_id);


--
-- Name: idx_escalation_policy_state_policy_ids; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_escalation_policy_state_policy_ids ON public.escalation_policy_state USING btree (escalation_policy_id, service_id);


--
-- Name: idx_heartbeat_monitor_service; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_heartbeat_monitor_service ON public.heartbeat_monitors USING btree (service_id);


--
-- Name: idx_integration_key_service; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_integration_key_service ON public.integration_keys USING btree (service_id);


--
-- Name: idx_labels_service_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_labels_service_id ON public.labels USING btree (tgt_service_id);


--
-- Name: idx_no_alert_duplicates; Type: INDEX; Schema: public; Owner: goalert
--

CREATE UNIQUE INDEX idx_no_alert_duplicates ON public.alerts USING btree (service_id, dedup_key);


--
-- Name: idx_notif_rule_creation_time; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_notif_rule_creation_time ON public.user_notification_rules USING btree (user_id, created_at);


--
-- Name: idx_notification_rule_users; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_notification_rule_users ON public.user_notification_rules USING btree (user_id);


--
-- Name: idx_np_cycle_alert_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_np_cycle_alert_id ON public.notification_policy_cycles USING btree (alert_id);


--
-- Name: idx_om_alert_log_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_om_alert_log_id ON public.outgoing_messages USING btree (alert_log_id);


--
-- Name: idx_om_alert_sent; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_om_alert_sent ON public.outgoing_messages USING btree (alert_id, sent_at);


--
-- Name: idx_om_cm_sent; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_om_cm_sent ON public.outgoing_messages USING btree (contact_method_id, sent_at);


--
-- Name: idx_om_ep_sent; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_om_ep_sent ON public.outgoing_messages USING btree (escalation_policy_id, sent_at);


--
-- Name: idx_om_last_status_sent; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_om_last_status_sent ON public.outgoing_messages USING btree (last_status, sent_at);


--
-- Name: idx_om_service_sent; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_om_service_sent ON public.outgoing_messages USING btree (service_id, sent_at);


--
-- Name: idx_om_user_sent; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_om_user_sent ON public.outgoing_messages USING btree (user_id, sent_at);


--
-- Name: idx_om_vcode_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_om_vcode_id ON public.outgoing_messages USING btree (user_verification_code_id);


--
-- Name: idx_outgoing_messages_notif_cycle; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_outgoing_messages_notif_cycle ON public.outgoing_messages USING btree (cycle_id);


--
-- Name: idx_outgoing_messages_provider_msg_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE UNIQUE INDEX idx_outgoing_messages_provider_msg_id ON public.outgoing_messages USING btree (provider_msg_id);


--
-- Name: idx_participant_rotation; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_participant_rotation ON public.rotation_participants USING btree (rotation_id);


--
-- Name: idx_rule_schedule; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_rule_schedule ON public.schedule_rules USING btree (schedule_id);


--
-- Name: idx_sched_oncall_times; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_sched_oncall_times ON public.schedule_on_call_users USING spgist (tstzrange(start_time, end_time));


--
-- Name: idx_schedule_on_call_once; Type: INDEX; Schema: public; Owner: goalert
--

CREATE UNIQUE INDEX idx_schedule_on_call_once ON public.schedule_on_call_users USING btree (schedule_id, user_id) WHERE (end_time IS NULL);


--
-- Name: idx_search_alerts_summary_eng; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_search_alerts_summary_eng ON public.alerts USING gin (to_tsvector('english'::regconfig, replace(lower(summary), '.'::text, ' '::text)));


--
-- Name: idx_search_escalation_policies_desc_eng; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_search_escalation_policies_desc_eng ON public.escalation_policies USING gin (to_tsvector('english'::regconfig, replace(lower(description), '.'::text, ' '::text)));


--
-- Name: idx_search_escalation_policies_name_eng; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_search_escalation_policies_name_eng ON public.escalation_policies USING gin (to_tsvector('english'::regconfig, replace(lower(name), '.'::text, ' '::text)));


--
-- Name: idx_search_rotations_desc_eng; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_search_rotations_desc_eng ON public.rotations USING gin (to_tsvector('english'::regconfig, replace(lower(description), '.'::text, ' '::text)));


--
-- Name: idx_search_rotations_name_eng; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_search_rotations_name_eng ON public.rotations USING gin (to_tsvector('english'::regconfig, replace(lower(name), '.'::text, ' '::text)));


--
-- Name: idx_search_schedules_desc_eng; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_search_schedules_desc_eng ON public.schedules USING gin (to_tsvector('english'::regconfig, replace(lower(description), '.'::text, ' '::text)));


--
-- Name: idx_search_schedules_name_eng; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_search_schedules_name_eng ON public.schedules USING gin (to_tsvector('english'::regconfig, replace(lower(name), '.'::text, ' '::text)));


--
-- Name: idx_search_services_desc_eng; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_search_services_desc_eng ON public.services USING gin (to_tsvector('english'::regconfig, replace(lower(description), '.'::text, ' '::text)));


--
-- Name: idx_search_services_name_eng; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_search_services_name_eng ON public.services USING gin (to_tsvector('english'::regconfig, replace(lower(name), '.'::text, ' '::text)));


--
-- Name: idx_search_users_name_eng; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_search_users_name_eng ON public.users USING gin (to_tsvector('english'::regconfig, replace(lower(name), '.'::text, ' '::text)));


--
-- Name: idx_target_schedule; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_target_schedule ON public.schedule_rules USING btree (schedule_id, tgt_rotation_id, tgt_user_id);


--
-- Name: idx_twilio_sms_alert_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_twilio_sms_alert_id ON public.twilio_sms_callbacks USING btree (alert_id);


--
-- Name: idx_twilio_sms_codes; Type: INDEX; Schema: public; Owner: goalert
--

CREATE UNIQUE INDEX idx_twilio_sms_codes ON public.twilio_sms_callbacks USING btree (phone_number, code);


--
-- Name: idx_twilio_sms_service_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_twilio_sms_service_id ON public.twilio_sms_callbacks USING btree (service_id);


--
-- Name: idx_unacked_alert_service; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_unacked_alert_service ON public.alerts USING btree (status, service_id);


--
-- Name: idx_user_overrides_schedule; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_user_overrides_schedule ON public.user_overrides USING btree (tgt_schedule_id, end_time);


--
-- Name: idx_user_status_updates; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_user_status_updates ON public.users USING btree (alert_status_log_contact_method_id) WHERE (alert_status_log_contact_method_id IS NOT NULL);


--
-- Name: idx_valid_contact_methods; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX idx_valid_contact_methods ON public.user_contact_methods USING btree (id) WHERE (NOT disabled);


--
-- Name: integration_keys_name_service_id; Type: INDEX; Schema: public; Owner: goalert
--

CREATE UNIQUE INDEX integration_keys_name_service_id ON public.integration_keys USING btree (lower(name), service_id);


--
-- Name: om_cm_time_test_verify_idx; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX om_cm_time_test_verify_idx ON public.outgoing_messages USING btree (contact_method_id, created_at) WHERE (message_type = ANY (ARRAY['test_notification'::public.enum_outgoing_messages_type, 'verification_message'::public.enum_outgoing_messages_type]));


--
-- Name: rotations_name; Type: INDEX; Schema: public; Owner: goalert
--

CREATE UNIQUE INDEX rotations_name ON public.rotations USING btree (lower(name));


--
-- Name: schedules_name; Type: INDEX; Schema: public; Owner: goalert
--

CREATE UNIQUE INDEX schedules_name ON public.schedules USING btree (lower(name));


--
-- Name: services_name; Type: INDEX; Schema: public; Owner: goalert
--

CREATE UNIQUE INDEX services_name ON public.services USING btree (lower(name));


--
-- Name: twilio_sms_errors_phone_number_outgoing_occurred_at_idx; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX twilio_sms_errors_phone_number_outgoing_occurred_at_idx ON public.twilio_sms_errors USING btree (phone_number, outgoing, occurred_at);


--
-- Name: twilio_voice_errors_phone_number_outgoing_occurred_at_idx; Type: INDEX; Schema: public; Owner: goalert
--

CREATE INDEX twilio_voice_errors_phone_number_outgoing_occurred_at_idx ON public.twilio_voice_errors USING btree (phone_number, outgoing, occurred_at);


--
-- Name: alerts trg_10_clear_ep_state_on_alert_close; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_10_clear_ep_state_on_alert_close AFTER UPDATE ON public.alerts FOR EACH ROW WHEN (((old.status <> new.status) AND (new.status = 'closed'::public.enum_alert_status))) EXECUTE FUNCTION public.fn_clear_ep_state_on_alert_close();


--
-- Name: services trg_10_clear_ep_state_on_svc_ep_change; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_10_clear_ep_state_on_svc_ep_change AFTER UPDATE ON public.services FOR EACH ROW WHEN ((old.escalation_policy_id <> new.escalation_policy_id)) EXECUTE FUNCTION public.fn_clear_ep_state_on_svc_ep_change();


--
-- Name: escalation_policy_steps trg_10_decr_ep_step_count_on_del; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_10_decr_ep_step_count_on_del BEFORE DELETE ON public.escalation_policy_steps FOR EACH ROW EXECUTE FUNCTION public.fn_decr_ep_step_count_on_del();


--
-- Name: rotation_participants trg_10_decr_part_count_on_del; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_10_decr_part_count_on_del BEFORE DELETE ON public.rotation_participants FOR EACH ROW EXECUTE FUNCTION public.fn_decr_part_count_on_del();


--
-- Name: escalation_policy_steps trg_10_incr_ep_step_count_on_add; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_10_incr_ep_step_count_on_add BEFORE INSERT ON public.escalation_policy_steps FOR EACH ROW EXECUTE FUNCTION public.fn_incr_ep_step_count_on_add();


--
-- Name: alerts trg_10_insert_ep_state_on_alert_insert; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_10_insert_ep_state_on_alert_insert AFTER INSERT ON public.alerts FOR EACH ROW WHEN ((new.status <> 'closed'::public.enum_alert_status)) EXECUTE FUNCTION public.fn_insert_ep_state_on_alert_insert();


--
-- Name: escalation_policy_steps trg_10_insert_ep_state_on_step_insert; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_10_insert_ep_state_on_step_insert AFTER INSERT ON public.escalation_policy_steps FOR EACH ROW WHEN ((new.step_number = 0)) EXECUTE FUNCTION public.fn_insert_ep_state_on_step_insert();


--
-- Name: escalation_policy_state trg_10_set_ep_state_svc_id_on_insert; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_10_set_ep_state_svc_id_on_insert BEFORE INSERT ON public.escalation_policy_state FOR EACH ROW WHEN ((new.service_id IS NULL)) EXECUTE FUNCTION public.fn_set_ep_state_svc_id_on_insert();


--
-- Name: alerts trg_20_clear_next_esc_on_alert_ack; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_20_clear_next_esc_on_alert_ack AFTER UPDATE ON public.alerts FOR EACH ROW WHEN (((new.status <> old.status) AND (old.status = 'active'::public.enum_alert_status))) EXECUTE FUNCTION public.fn_clear_next_esc_on_alert_ack();


--
-- Name: rotation_participants trg_20_decr_rot_part_position_on_delete; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_20_decr_rot_part_position_on_delete AFTER DELETE ON public.rotation_participants FOR EACH ROW EXECUTE FUNCTION public.fn_decr_rot_part_position_on_delete();


--
-- Name: escalation_policy_state trg_20_lock_svc_on_force_escalation; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_20_lock_svc_on_force_escalation BEFORE UPDATE ON public.escalation_policy_state FOR EACH ROW WHEN (((new.force_escalation <> old.force_escalation) AND new.force_escalation)) EXECUTE FUNCTION public.fn_lock_svc_on_force_escalation();


--
-- Name: rotation_participants trg_30_advance_or_end_rot_on_part_del; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_30_advance_or_end_rot_on_part_del BEFORE DELETE ON public.rotation_participants FOR EACH ROW EXECUTE FUNCTION public.fn_advance_or_end_rot_on_part_del();


--
-- Name: escalation_policy_state trg_30_trig_alert_on_force_escalation; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_30_trig_alert_on_force_escalation AFTER UPDATE ON public.escalation_policy_state FOR EACH ROW WHEN (((new.force_escalation <> old.force_escalation) AND new.force_escalation)) EXECUTE FUNCTION public.fn_trig_alert_on_force_escalation();


--
-- Name: alerts trg_clear_dedup_on_close; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_clear_dedup_on_close BEFORE UPDATE ON public.alerts FOR EACH ROW WHEN (((new.status <> old.status) AND (new.status = 'closed'::public.enum_alert_status))) EXECUTE FUNCTION public.fn_clear_dedup_on_close();


--
-- Name: config trg_config_update; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_config_update AFTER INSERT ON public.config FOR EACH ROW EXECUTE FUNCTION public.fn_notify_config_refresh();


--
-- Name: escalation_policy_steps trg_decr_ep_step_number_on_delete; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_decr_ep_step_number_on_delete AFTER DELETE ON public.escalation_policy_steps FOR EACH ROW EXECUTE FUNCTION public.fn_decr_ep_step_number_on_delete();


--
-- Name: alerts trg_enforce_alert_limit; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_alert_limit AFTER INSERT ON public.alerts NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_alert_limit();


--
-- Name: user_calendar_subscriptions trg_enforce_calendar_subscriptions_per_user_limit; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_calendar_subscriptions_per_user_limit AFTER INSERT ON public.user_calendar_subscriptions NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_calendar_subscriptions_per_user_limit();


--
-- Name: user_contact_methods trg_enforce_contact_method_limit; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_contact_method_limit AFTER INSERT ON public.user_contact_methods NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_contact_method_limit();


--
-- Name: escalation_policy_actions trg_enforce_ep_step_action_limit; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_ep_step_action_limit AFTER INSERT ON public.escalation_policy_actions NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_ep_step_action_limit();


--
-- Name: escalation_policy_steps trg_enforce_ep_step_limit; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_ep_step_limit AFTER INSERT ON public.escalation_policy_steps NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_ep_step_limit();


--
-- Name: heartbeat_monitors trg_enforce_heartbeat_monitor_limit; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_heartbeat_monitor_limit AFTER INSERT ON public.heartbeat_monitors NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_heartbeat_limit();


--
-- Name: integration_keys trg_enforce_integration_key_limit; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_integration_key_limit AFTER INSERT ON public.integration_keys NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_integration_key_limit();


--
-- Name: user_notification_rules trg_enforce_notification_rule_limit; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_notification_rule_limit AFTER INSERT ON public.user_notification_rules NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_notification_rule_limit();


--
-- Name: rotation_participants trg_enforce_rot_part_position_no_gaps; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_rot_part_position_no_gaps AFTER UPDATE ON public.rotation_participants DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_rot_part_position_no_gaps();


--
-- Name: rotation_participants trg_enforce_rotation_participant_limit; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_rotation_participant_limit AFTER INSERT ON public.rotation_participants NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_rotation_participant_limit();


--
-- Name: schedule_rules trg_enforce_schedule_rule_limit; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_schedule_rule_limit AFTER INSERT ON public.schedule_rules NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_schedule_rule_limit();


--
-- Name: schedule_rules trg_enforce_schedule_target_limit; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_schedule_target_limit AFTER INSERT ON public.schedule_rules NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_schedule_target_limit();


--
-- Name: users trg_enforce_status_update_same_user; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_enforce_status_update_same_user BEFORE INSERT OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_status_update_same_user();


--
-- Name: user_overrides trg_enforce_user_overide_no_conflict; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_user_overide_no_conflict AFTER INSERT OR UPDATE ON public.user_overrides NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_user_overide_no_conflict();


--
-- Name: user_overrides trg_enforce_user_override_schedule_limit; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_enforce_user_override_schedule_limit AFTER INSERT ON public.user_overrides NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_user_override_schedule_limit();


--
-- Name: escalation_policy_steps trg_ep_step_number_no_gaps; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE CONSTRAINT TRIGGER trg_ep_step_number_no_gaps AFTER UPDATE ON public.escalation_policy_steps DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_ep_step_number_no_gaps();


--
-- Name: escalation_policy_steps trg_inc_ep_step_number_on_insert; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_inc_ep_step_number_on_insert BEFORE INSERT ON public.escalation_policy_steps FOR EACH ROW EXECUTE FUNCTION public.fn_inc_ep_step_number_on_insert();


--
-- Name: rotation_participants trg_inc_rot_part_position_on_insert; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_inc_rot_part_position_on_insert BEFORE INSERT ON public.rotation_participants FOR EACH ROW EXECUTE FUNCTION public.fn_inc_rot_part_position_on_insert();


--
-- Name: rotation_participants trg_incr_part_count_on_add; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_incr_part_count_on_add BEFORE INSERT ON public.rotation_participants FOR EACH ROW EXECUTE FUNCTION public.fn_incr_part_count_on_add();


--
-- Name: auth_basic_users trg_insert_basic_user; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_insert_basic_user AFTER INSERT ON public.auth_basic_users FOR EACH ROW EXECUTE FUNCTION public.fn_insert_basic_user();


--
-- Name: user_notification_rules trg_notification_rule_same_user; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_notification_rule_same_user BEFORE INSERT OR UPDATE ON public.user_notification_rules FOR EACH ROW EXECUTE FUNCTION public.fn_notification_rule_same_user();


--
-- Name: alerts trg_prevent_reopen; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_prevent_reopen BEFORE UPDATE OF status ON public.alerts FOR EACH ROW EXECUTE FUNCTION public.fn_prevent_reopen();


--
-- Name: rotation_state trg_set_rot_state_pos_on_active_change; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_set_rot_state_pos_on_active_change BEFORE UPDATE ON public.rotation_state FOR EACH ROW WHEN ((new.rotation_participant_id <> old.rotation_participant_id)) EXECUTE FUNCTION public.fn_set_rot_state_pos_on_active_change();


--
-- Name: rotation_participants trg_set_rot_state_pos_on_part_reorder; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_set_rot_state_pos_on_part_reorder BEFORE UPDATE ON public.rotation_participants FOR EACH ROW WHEN ((new."position" <> old."position")) EXECUTE FUNCTION public.fn_set_rot_state_pos_on_part_reorder();


--
-- Name: rotation_participants trg_start_rotation_on_first_part_add; Type: TRIGGER; Schema: public; Owner: goalert
--

CREATE TRIGGER trg_start_rotation_on_first_part_add AFTER INSERT ON public.rotation_participants FOR EACH ROW EXECUTE FUNCTION public.fn_start_rotation_on_first_part_add();


--
-- Name: alert_metrics alert_metrics_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alert_metrics
    ADD CONSTRAINT alert_metrics_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- Name: alert_status_subscriptions alert_status_subscriptions_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alert_status_subscriptions
    ADD CONSTRAINT alert_status_subscriptions_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- Name: alert_status_subscriptions alert_status_subscriptions_channel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alert_status_subscriptions
    ADD CONSTRAINT alert_status_subscriptions_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES public.notification_channels(id) ON DELETE CASCADE;


--
-- Name: alert_status_subscriptions alert_status_subscriptions_contact_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alert_status_subscriptions
    ADD CONSTRAINT alert_status_subscriptions_contact_method_id_fkey FOREIGN KEY (contact_method_id) REFERENCES public.user_contact_methods(id) ON DELETE CASCADE;


--
-- Name: alerts alerts_services_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_services_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: auth_basic_users auth_basic_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_basic_users
    ADD CONSTRAINT auth_basic_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: auth_subjects auth_subjects_cm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_subjects
    ADD CONSTRAINT auth_subjects_cm_id_fkey FOREIGN KEY (cm_id) REFERENCES public.user_contact_methods(id) ON DELETE CASCADE;


--
-- Name: auth_subjects auth_subjects_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_subjects
    ADD CONSTRAINT auth_subjects_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: auth_user_sessions auth_user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.auth_user_sessions
    ADD CONSTRAINT auth_user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: ep_step_on_call_users ep_step_on_call_users_ep_step_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.ep_step_on_call_users
    ADD CONSTRAINT ep_step_on_call_users_ep_step_id_fkey FOREIGN KEY (ep_step_id) REFERENCES public.escalation_policy_steps(id) ON DELETE CASCADE;


--
-- Name: ep_step_on_call_users ep_step_on_call_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.ep_step_on_call_users
    ADD CONSTRAINT ep_step_on_call_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_actions escalation_policy_actions_channel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT escalation_policy_actions_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES public.notification_channels(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_actions escalation_policy_actions_escalation_policy_step_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT escalation_policy_actions_escalation_policy_step_id_fkey FOREIGN KEY (escalation_policy_step_id) REFERENCES public.escalation_policy_steps(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_actions escalation_policy_actions_rotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT escalation_policy_actions_rotation_id_fkey FOREIGN KEY (rotation_id) REFERENCES public.rotations(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_actions escalation_policy_actions_schedule_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT escalation_policy_actions_schedule_id_fkey1 FOREIGN KEY (schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_actions escalation_policy_actions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT escalation_policy_actions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_state escalation_policy_state_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT escalation_policy_state_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_state escalation_policy_state_escalation_policy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT escalation_policy_state_escalation_policy_id_fkey FOREIGN KEY (escalation_policy_id) REFERENCES public.escalation_policies(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_state escalation_policy_state_escalation_policy_step_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT escalation_policy_state_escalation_policy_step_id_fkey FOREIGN KEY (escalation_policy_step_id) REFERENCES public.escalation_policy_steps(id) ON DELETE SET NULL;


--
-- Name: escalation_policy_state escalation_policy_state_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT escalation_policy_state_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_steps escalation_policy_steps_escalation_policy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_steps
    ADD CONSTRAINT escalation_policy_steps_escalation_policy_id_fkey FOREIGN KEY (escalation_policy_id) REFERENCES public.escalation_policies(id) ON DELETE CASCADE;


--
-- Name: heartbeat_monitors heartbeat_monitors_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.heartbeat_monitors
    ADD CONSTRAINT heartbeat_monitors_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: integration_keys integration_keys_services_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.integration_keys
    ADD CONSTRAINT integration_keys_services_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: labels labels_tgt_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT labels_tgt_service_id_fkey FOREIGN KEY (tgt_service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: notification_policy_cycles notification_policy_cycles_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.notification_policy_cycles
    ADD CONSTRAINT notification_policy_cycles_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- Name: notification_policy_cycles notification_policy_cycles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.notification_policy_cycles
    ADD CONSTRAINT notification_policy_cycles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_alert_log_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_alert_log_id_fkey FOREIGN KEY (alert_log_id) REFERENCES public.alert_logs(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_channel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES public.notification_channels(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_contact_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_contact_method_id_fkey FOREIGN KEY (contact_method_id) REFERENCES public.user_contact_methods(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_cycle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_cycle_id_fkey FOREIGN KEY (cycle_id) REFERENCES public.notification_policy_cycles(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_escalation_policy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_escalation_policy_id_fkey FOREIGN KEY (escalation_policy_id) REFERENCES public.escalation_policies(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_user_verification_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_user_verification_code_id_fkey FOREIGN KEY (user_verification_code_id) REFERENCES public.user_verification_codes(id) ON DELETE CASCADE;


--
-- Name: rotation_participants rotation_participants_rotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.rotation_participants
    ADD CONSTRAINT rotation_participants_rotation_id_fkey FOREIGN KEY (rotation_id) REFERENCES public.rotations(id) ON DELETE CASCADE;


--
-- Name: rotation_participants rotation_participants_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.rotation_participants
    ADD CONSTRAINT rotation_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: rotation_state rotation_state_rotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.rotation_state
    ADD CONSTRAINT rotation_state_rotation_id_fkey FOREIGN KEY (rotation_id) REFERENCES public.rotations(id) ON DELETE CASCADE;


--
-- Name: rotation_state rotation_state_rotation_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.rotation_state
    ADD CONSTRAINT rotation_state_rotation_participant_id_fkey FOREIGN KEY (rotation_participant_id) REFERENCES public.rotation_participants(id) DEFERRABLE;


--
-- Name: schedule_data schedule_data_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedule_data
    ADD CONSTRAINT schedule_data_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: schedule_on_call_users schedule_on_call_users_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedule_on_call_users
    ADD CONSTRAINT schedule_on_call_users_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: schedule_on_call_users schedule_on_call_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedule_on_call_users
    ADD CONSTRAINT schedule_on_call_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: schedule_rules schedule_rules_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedule_rules
    ADD CONSTRAINT schedule_rules_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: schedule_rules schedule_rules_tgt_rotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedule_rules
    ADD CONSTRAINT schedule_rules_tgt_rotation_id_fkey FOREIGN KEY (tgt_rotation_id) REFERENCES public.rotations(id) ON DELETE CASCADE;


--
-- Name: schedule_rules schedule_rules_tgt_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.schedule_rules
    ADD CONSTRAINT schedule_rules_tgt_user_id_fkey FOREIGN KEY (tgt_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: services services_escalation_policy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_escalation_policy_id_fkey FOREIGN KEY (escalation_policy_id) REFERENCES public.escalation_policies(id);


--
-- Name: escalation_policy_state svc_ep_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT svc_ep_fkey FOREIGN KEY (service_id, escalation_policy_id) REFERENCES public.services(id, escalation_policy_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: twilio_sms_callbacks twilio_sms_callbacks_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.twilio_sms_callbacks
    ADD CONSTRAINT twilio_sms_callbacks_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- Name: twilio_sms_callbacks twilio_sms_callbacks_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.twilio_sms_callbacks
    ADD CONSTRAINT twilio_sms_callbacks_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: user_calendar_subscriptions user_calendar_subscriptions_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_calendar_subscriptions
    ADD CONSTRAINT user_calendar_subscriptions_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: user_calendar_subscriptions user_calendar_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_calendar_subscriptions
    ADD CONSTRAINT user_calendar_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_contact_methods user_contact_methods_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_contact_methods
    ADD CONSTRAINT user_contact_methods_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_favorites user_favorites_tgt_escalation_policy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_tgt_escalation_policy_id_fkey FOREIGN KEY (tgt_escalation_policy_id) REFERENCES public.escalation_policies(id) ON DELETE CASCADE;


--
-- Name: user_favorites user_favorites_tgt_rotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_tgt_rotation_id_fkey FOREIGN KEY (tgt_rotation_id) REFERENCES public.rotations(id) ON DELETE CASCADE;


--
-- Name: user_favorites user_favorites_tgt_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_tgt_schedule_id_fkey FOREIGN KEY (tgt_schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: user_favorites user_favorites_tgt_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_tgt_service_id_fkey FOREIGN KEY (tgt_service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: user_favorites user_favorites_tgt_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_tgt_user_id_fkey FOREIGN KEY (tgt_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_favorites user_favorites_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_notification_rules user_notification_rules_contact_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_notification_rules
    ADD CONSTRAINT user_notification_rules_contact_method_id_fkey FOREIGN KEY (contact_method_id) REFERENCES public.user_contact_methods(id) ON DELETE CASCADE;


--
-- Name: user_notification_rules user_notification_rules_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_notification_rules
    ADD CONSTRAINT user_notification_rules_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_overrides user_overrides_add_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_overrides
    ADD CONSTRAINT user_overrides_add_user_id_fkey FOREIGN KEY (add_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_overrides user_overrides_remove_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_overrides
    ADD CONSTRAINT user_overrides_remove_user_id_fkey FOREIGN KEY (remove_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_overrides user_overrides_tgt_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_overrides
    ADD CONSTRAINT user_overrides_tgt_schedule_id_fkey FOREIGN KEY (tgt_schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: user_slack_data user_slack_data_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_slack_data
    ADD CONSTRAINT user_slack_data_id_fkey FOREIGN KEY (id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_verification_codes user_verification_codes_contact_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.user_verification_codes
    ADD CONSTRAINT user_verification_codes_contact_method_id_fkey FOREIGN KEY (contact_method_id) REFERENCES public.user_contact_methods(id) ON DELETE CASCADE;


--
-- Name: users users_alert_status_log_contact_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: goalert
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_alert_status_log_contact_method_id_fkey FOREIGN KEY (alert_status_log_contact_method_id) REFERENCES public.user_contact_methods(id) ON DELETE SET NULL DEFERRABLE;


--
-- PostgreSQL database dump complete
--

