--
-- PostgreSQL database dump
--

\restrict tTtRfiORzqUE2v9t9EKJOhE1t6J5nsqzISIKRV1nNEOPnBiNMlAq3qNh3n6QRy5

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '404db5ec-6407-4748-8b7b-43ec6cd244f2', 'authenticated', 'authenticated', NULL, '$2a$10$ZEaNQpLL6bjBDu9iuhw0MeuVPTJXT3o343dad9BtkIg7ZJPdEbYIi', NULL, NULL, '', '2026-03-23 16:06:58.102303+00', '', NULL, '', '', NULL, '2026-03-23 16:07:01.890676+00', '{"provider": "phone", "providers": ["phone"]}', '{"sub": "404db5ec-6407-4748-8b7b-43ec6cd244f2", "email_verified": false, "phone_verified": false}', NULL, '2026-03-21 07:48:17.803348+00', '2026-05-04 21:03:33.074237+00', '233549628060', '2026-03-23 16:07:01.880242+00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '68c2027e-dc87-4dad-b817-8b039091e41f', 'authenticated', 'authenticated', NULL, '$2a$10$NhU44iOD0i2BqLjJ4daaNOiKz4nXgYfeyexTnV2xH/3cWiqKxB1eK', NULL, NULL, '', '2026-04-02 16:27:22.758803+00', '', NULL, '', '', NULL, '2026-04-02 16:27:29.055071+00', '{"provider": "phone", "providers": ["phone"]}', '{"sub": "68c2027e-dc87-4dad-b817-8b039091e41f", "email_verified": false, "phone_verified": false}', NULL, '2026-03-21 07:41:23.805901+00', '2026-05-11 13:59:26.615149+00', '233535891956', '2026-04-02 16:27:29.046479+00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', 'authenticated', 'authenticated', NULL, '$2a$10$GTJjXXLfVwdxIzDiblPvK.ukurUk6KcuGoOcW0t9w9w6QCwKmqF4G', NULL, NULL, '', '2026-03-20 23:19:25.277311+00', '', NULL, '', '', NULL, '2026-03-20 23:19:30.443371+00', '{"provider": "phone", "providers": ["phone"]}', '{"sub": "273649c3-15bc-4026-b9fb-a7f44aa0ec16", "email_verified": false, "phone_verified": false}', NULL, '2026-03-17 23:41:28.614658+00', '2026-04-01 08:04:18.195678+00', '233530823904', '2026-03-20 23:19:30.44028+00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES ('00000000-0000-0000-0000-000000000000', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', 'authenticated', 'authenticated', NULL, '$2a$10$AKNXRTuzY4I3z7U8MGzjSuoTdcIIHZvArqjE5bB9ngJDWkMmfpH.C', NULL, NULL, '', '2026-03-20 23:34:49.070722+00', '', NULL, '', '', NULL, '2026-03-20 23:36:17.352943+00', '{"provider": "phone", "providers": ["phone"]}', '{"sub": "f897b65b-33e4-4cea-b702-d6d4cb2b8cd1", "email_verified": false, "phone_verified": false}', NULL, '2026-03-20 23:33:41.729088+00', '2026-04-04 12:44:48.053209+00', '233531307502', '2026-03-20 23:36:17.330565+00', '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('273649c3-15bc-4026-b9fb-a7f44aa0ec16', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', '{"sub": "273649c3-15bc-4026-b9fb-a7f44aa0ec16", "email_verified": false, "phone_verified": false}', 'phone', '2026-03-17 23:41:28.631732+00', '2026-03-17 23:41:28.631774+00', '2026-03-17 23:41:28.631774+00', '912a5d3a-7ff8-4617-93a3-338695b6c901');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', '{"sub": "f897b65b-33e4-4cea-b702-d6d4cb2b8cd1", "email_verified": false, "phone_verified": false}', 'phone', '2026-03-20 23:33:41.75572+00', '2026-03-20 23:33:41.755771+00', '2026-03-20 23:33:41.755771+00', 'a73d34a7-f700-433f-a1c8-2be2ea2ed1bc');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('68c2027e-dc87-4dad-b817-8b039091e41f', '68c2027e-dc87-4dad-b817-8b039091e41f', '{"sub": "68c2027e-dc87-4dad-b817-8b039091e41f", "email_verified": false, "phone_verified": false}', 'phone', '2026-03-21 07:41:23.850496+00', '2026-03-21 07:41:23.850551+00', '2026-03-21 07:41:23.850551+00', 'f72b1ebf-b4cf-4124-aa90-440c7a90afe4');
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) VALUES ('404db5ec-6407-4748-8b7b-43ec6cd244f2', '404db5ec-6407-4748-8b7b-43ec6cd244f2', '{"sub": "404db5ec-6407-4748-8b7b-43ec6cd244f2", "email_verified": false, "phone_verified": false}', 'phone', '2026-03-21 07:48:17.814727+00', '2026-03-21 07:48:17.814776+00', '2026-03-21 07:48:17.814776+00', 'd8067ca7-4b22-4095-9ead-c5d660f9f4e1');


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('e0e0d65d-83f6-43e5-91b3-b3ce5daa887d', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', '2026-03-17 23:41:38.266732+00', '2026-03-17 23:41:38.266732+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36', '102.176.101.84', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('349b7eda-e0f3-4cc1-a56b-ef22c25f87bd', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', '2026-03-18 00:20:02.716249+00', '2026-03-18 00:20:02.716249+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36', '102.176.101.84', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('fe008b0b-0ce1-482d-a27e-0f8c5d095059', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', '2026-03-18 00:37:38.765918+00', '2026-03-18 06:22:28.008255+00', NULL, 'aal1', NULL, '2026-03-18 06:22:28.00816', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36', '102.176.101.84', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('1c49ff4d-c63c-4197-b167-70c5c061d547', '404db5ec-6407-4748-8b7b-43ec6cd244f2', '2026-03-23 16:07:01.891356+00', '2026-05-04 21:03:33.086812+00', NULL, 'aal1', NULL, '2026-05-04 21:03:33.08671', 'Dart/3.11 (dart:io)', '154.161.7.24', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('babadbac-624c-484a-8537-32073955d7f3', '68c2027e-dc87-4dad-b817-8b039091e41f', '2026-04-02 16:27:29.057028+00', '2026-05-11 13:59:26.618613+00', NULL, 'aal1', NULL, '2026-05-11 13:59:26.618513', 'Dart/3.11 (dart:io)', '154.161.8.125', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('33488cc0-0c2c-44ab-ac2d-4d6303ebc1f7', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', '2026-03-20 23:19:30.443464+00', '2026-04-01 08:04:18.201759+00', NULL, 'aal1', NULL, '2026-04-01 08:04:18.201359', 'Dart/3.11 (dart:io)', '102.176.65.186', NULL, NULL, NULL, NULL, NULL);
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) VALUES ('d5b8cca5-411d-467c-b1b7-7076185e4adc', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', '2026-03-20 23:36:17.353663+00', '2026-04-04 12:44:48.06005+00', NULL, 'aal1', NULL, '2026-04-04 12:44:48.059939', 'Dart/3.11 (dart:io)', '154.161.110.99', NULL, NULL, NULL, NULL, NULL);


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('e0e0d65d-83f6-43e5-91b3-b3ce5daa887d', '2026-03-17 23:41:38.279902+00', '2026-03-17 23:41:38.279902+00', 'otp', '6b94275b-6046-4ecb-8126-90be2c304481');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('349b7eda-e0f3-4cc1-a56b-ef22c25f87bd', '2026-03-18 00:20:02.732687+00', '2026-03-18 00:20:02.732687+00', 'otp', '94826896-1ce4-4b79-9642-9a0847772f02');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('fe008b0b-0ce1-482d-a27e-0f8c5d095059', '2026-03-18 00:37:38.80741+00', '2026-03-18 00:37:38.80741+00', 'otp', 'f734a70f-e4ac-4032-b9ff-ada14aabc29b');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('33488cc0-0c2c-44ab-ac2d-4d6303ebc1f7', '2026-03-20 23:19:30.474489+00', '2026-03-20 23:19:30.474489+00', 'otp', 'e238a606-e56e-4180-986f-66365c2a151f');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('d5b8cca5-411d-467c-b1b7-7076185e4adc', '2026-03-20 23:36:17.395398+00', '2026-03-20 23:36:17.395398+00', 'otp', '14160d7a-73b6-446e-964d-530c25757899');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('1c49ff4d-c63c-4197-b167-70c5c061d547', '2026-03-23 16:07:01.903443+00', '2026-03-23 16:07:01.903443+00', 'otp', 'd8c9f85c-f32d-48cf-ac28-cc04ebe9fd80');
INSERT INTO auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) VALUES ('babadbac-624c-484a-8537-32073955d7f3', '2026-04-02 16:27:29.104775+00', '2026-04-02 16:27:29.104775+00', 'otp', 'bfe146b6-4bde-4268-8f3b-5a31b5359e40');


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 1, '7l53bq2546ud', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', false, '2026-03-17 23:41:38.270748+00', '2026-03-17 23:41:38.270748+00', NULL, 'e0e0d65d-83f6-43e5-91b3-b3ce5daa887d');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 2, 'bzsdiosvkyxt', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', false, '2026-03-18 00:20:02.723948+00', '2026-03-18 00:20:02.723948+00', NULL, '349b7eda-e0f3-4cc1-a56b-ef22c25f87bd');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 19, 'hej4szn3qw5o', '404db5ec-6407-4748-8b7b-43ec6cd244f2', true, '2026-03-23 18:58:11.108038+00', '2026-04-11 13:21:34.919564+00', 'fh7f3auq3iew', '1c49ff4d-c63c-4197-b167-70c5c061d547');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 3, 'm6h2k2nziszf', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', true, '2026-03-18 00:37:38.783411+00', '2026-03-18 05:23:00.532244+00', NULL, 'fe008b0b-0ce1-482d-a27e-0f8c5d095059');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 4, 'vy7f74auki4y', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', true, '2026-03-18 05:23:00.55069+00', '2026-03-18 06:22:27.989158+00', 'm6h2k2nziszf', 'fe008b0b-0ce1-482d-a27e-0f8c5d095059');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 5, 'lcskera4zof7', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', false, '2026-03-18 06:22:27.998688+00', '2026-03-18 06:22:27.998688+00', 'vy7f74auki4y', 'fe008b0b-0ce1-482d-a27e-0f8c5d095059');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 47, 'viachefcjzpi', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-04-09 19:53:51.245971+00', '2026-04-15 21:49:03.547625+00', 'dac5hrejbhgk', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 49, 'khvo2ltl5now', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-04-15 21:49:03.566911+00', '2026-04-20 19:53:31.344034+00', 'viachefcjzpi', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 50, 'bn7aimmz5dfy', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-04-20 19:53:31.361294+00', '2026-04-26 06:42:07.243191+00', 'khvo2ltl5now', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 51, '7rjzsrx4xvkk', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-04-26 06:42:07.262724+00', '2026-04-29 16:27:35.92641+00', 'bn7aimmz5dfy', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 6, '7xb3spyricnr', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', true, '2026-03-20 23:19:30.457886+00', '2026-03-22 18:16:40.962648+00', NULL, '33488cc0-0c2c-44ab-ac2d-4d6303ebc1f7');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 52, 'lsoefbbxyeep', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-04-29 16:27:35.943729+00', '2026-05-01 07:28:30.084376+00', '7rjzsrx4xvkk', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 53, 'rvqrh2ujocuw', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-05-01 07:28:30.104278+00', '2026-05-02 16:57:40.554593+00', 'lsoefbbxyeep', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 12, 'tdwi3hqzgi7a', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', true, '2026-03-22 18:16:40.978104+00', '2026-03-22 22:11:36.96261+00', '7xb3spyricnr', '33488cc0-0c2c-44ab-ac2d-4d6303ebc1f7');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 54, 'clmllyd7tclx', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-05-02 16:57:40.57843+00', '2026-05-04 15:14:20.727339+00', 'rvqrh2ujocuw', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 55, 'b7kxq37vhmfh', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-05-04 15:14:20.742765+00', '2026-05-04 20:43:53.063817+00', 'clmllyd7tclx', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 48, 'nsmfbiyjpbur', '404db5ec-6407-4748-8b7b-43ec6cd244f2', true, '2026-04-11 13:21:34.985349+00', '2026-05-04 21:03:32.993186+00', 'hej4szn3qw5o', '1c49ff4d-c63c-4197-b167-70c5c061d547');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 57, '632fp6sw2wvg', '404db5ec-6407-4748-8b7b-43ec6cd244f2', false, '2026-05-04 21:03:33.058109+00', '2026-05-04 21:03:33.058109+00', 'nsmfbiyjpbur', '1c49ff4d-c63c-4197-b167-70c5c061d547');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 18, 'fh7f3auq3iew', '404db5ec-6407-4748-8b7b-43ec6cd244f2', true, '2026-03-23 16:07:01.896205+00', '2026-03-23 18:58:11.094449+00', NULL, '1c49ff4d-c63c-4197-b167-70c5c061d547');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 7, 'bnz6w2lc7qhh', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', true, '2026-03-20 23:36:17.372516+00', '2026-03-23 22:07:20.427225+00', NULL, 'd5b8cca5-411d-467c-b1b7-7076185e4adc');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 56, 'wog5bluo4nt5', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-05-04 20:43:53.080002+00', '2026-05-05 20:45:25.23488+00', 'b7kxq37vhmfh', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 58, 'qok4dkbc6ly5', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-05-05 20:45:25.25336+00', '2026-05-05 23:04:44.726463+00', 'wog5bluo4nt5', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 59, '6mcg7yst3w43', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-05-05 23:04:44.751548+00', '2026-05-10 19:18:53.655742+00', 'qok4dkbc6ly5', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 20, 'khob3haaio2c', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', true, '2026-03-23 22:07:20.44196+00', '2026-03-26 22:23:02.495758+00', 'bnz6w2lc7qhh', 'd5b8cca5-411d-467c-b1b7-7076185e4adc');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 14, 'iatd34e7vbzm', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', true, '2026-03-22 22:11:36.977895+00', '2026-03-27 18:29:25.989033+00', 'tdwi3hqzgi7a', '33488cc0-0c2c-44ab-ac2d-4d6303ebc1f7');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 60, 'jdn35iqbhtaw', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-05-10 19:18:53.671594+00', '2026-05-11 13:59:26.588919+00', '6mcg7yst3w43', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 61, 'kyx5rp737hgs', '68c2027e-dc87-4dad-b817-8b039091e41f', false, '2026-05-11 13:59:26.608358+00', '2026-05-11 13:59:26.608358+00', 'jdn35iqbhtaw', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 24, 'ddnyxm3rcayr', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', true, '2026-03-27 18:29:26.005316+00', '2026-03-30 11:35:07.276162+00', 'iatd34e7vbzm', '33488cc0-0c2c-44ab-ac2d-4d6303ebc1f7');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 28, 'pwf6x7uwqh4t', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', true, '2026-03-30 11:35:07.290114+00', '2026-04-01 07:04:56.17335+00', 'ddnyxm3rcayr', '33488cc0-0c2c-44ab-ac2d-4d6303ebc1f7');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 31, 'p5ndxoretxih', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', true, '2026-04-01 07:04:56.190212+00', '2026-04-01 08:04:18.171608+00', 'pwf6x7uwqh4t', '33488cc0-0c2c-44ab-ac2d-4d6303ebc1f7');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 32, '2yfsnb5pctov', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', false, '2026-04-01 08:04:18.187641+00', '2026-04-01 08:04:18.187641+00', 'p5ndxoretxih', '33488cc0-0c2c-44ab-ac2d-4d6303ebc1f7');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 23, 'r4dgzmlou6ge', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', true, '2026-03-26 22:23:02.50825+00', '2026-04-01 20:31:34.609802+00', 'khob3haaio2c', 'd5b8cca5-411d-467c-b1b7-7076185e4adc');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 35, 'gprnpeanzjdt', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', true, '2026-04-01 20:31:34.631533+00', '2026-04-04 12:44:48.011962+00', 'r4dgzmlou6ge', 'd5b8cca5-411d-467c-b1b7-7076185e4adc');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 42, 'hb7znmrwesnp', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', false, '2026-04-04 12:44:48.036953+00', '2026-04-04 12:44:48.036953+00', 'gprnpeanzjdt', 'd5b8cca5-411d-467c-b1b7-7076185e4adc');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 41, 'fwt7igdoyvzk', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-04-02 16:27:29.079838+00', '2026-04-05 08:59:33.973284+00', NULL, 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 43, 'vfzan5ff2qkx', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-04-05 08:59:34.001336+00', '2026-04-05 22:02:51.686573+00', 'fwt7igdoyvzk', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 44, 'b5h67h3m2xyv', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-04-05 22:02:51.705767+00', '2026-04-06 19:30:55.870743+00', 'vfzan5ff2qkx', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 45, '5hoypqke4zhz', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-04-06 19:30:55.893238+00', '2026-04-06 20:40:03.847055+00', 'b5h67h3m2xyv', 'babadbac-624c-484a-8537-32073955d7f3');
INSERT INTO auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) VALUES ('00000000-0000-0000-0000-000000000000', 46, 'dac5hrejbhgk', '68c2027e-dc87-4dad-b817-8b039091e41f', true, '2026-04-06 20:40:03.863219+00', '2026-04-09 19:53:51.225168+00', '5hoypqke4zhz', 'babadbac-624c-484a-8537-32073955d7f3');


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO auth.schema_migrations (version) VALUES ('20171026211738');
INSERT INTO auth.schema_migrations (version) VALUES ('20171026211808');
INSERT INTO auth.schema_migrations (version) VALUES ('20171026211834');
INSERT INTO auth.schema_migrations (version) VALUES ('20180103212743');
INSERT INTO auth.schema_migrations (version) VALUES ('20180108183307');
INSERT INTO auth.schema_migrations (version) VALUES ('20180119214651');
INSERT INTO auth.schema_migrations (version) VALUES ('20180125194653');
INSERT INTO auth.schema_migrations (version) VALUES ('00');
INSERT INTO auth.schema_migrations (version) VALUES ('20210710035447');
INSERT INTO auth.schema_migrations (version) VALUES ('20210722035447');
INSERT INTO auth.schema_migrations (version) VALUES ('20210730183235');
INSERT INTO auth.schema_migrations (version) VALUES ('20210909172000');
INSERT INTO auth.schema_migrations (version) VALUES ('20210927181326');
INSERT INTO auth.schema_migrations (version) VALUES ('20211122151130');
INSERT INTO auth.schema_migrations (version) VALUES ('20211124214934');
INSERT INTO auth.schema_migrations (version) VALUES ('20211202183645');
INSERT INTO auth.schema_migrations (version) VALUES ('20220114185221');
INSERT INTO auth.schema_migrations (version) VALUES ('20220114185340');
INSERT INTO auth.schema_migrations (version) VALUES ('20220224000811');
INSERT INTO auth.schema_migrations (version) VALUES ('20220323170000');
INSERT INTO auth.schema_migrations (version) VALUES ('20220429102000');
INSERT INTO auth.schema_migrations (version) VALUES ('20220531120530');
INSERT INTO auth.schema_migrations (version) VALUES ('20220614074223');
INSERT INTO auth.schema_migrations (version) VALUES ('20220811173540');
INSERT INTO auth.schema_migrations (version) VALUES ('20221003041349');
INSERT INTO auth.schema_migrations (version) VALUES ('20221003041400');
INSERT INTO auth.schema_migrations (version) VALUES ('20221011041400');
INSERT INTO auth.schema_migrations (version) VALUES ('20221020193600');
INSERT INTO auth.schema_migrations (version) VALUES ('20221021073300');
INSERT INTO auth.schema_migrations (version) VALUES ('20221021082433');
INSERT INTO auth.schema_migrations (version) VALUES ('20221027105023');
INSERT INTO auth.schema_migrations (version) VALUES ('20221114143122');
INSERT INTO auth.schema_migrations (version) VALUES ('20221114143410');
INSERT INTO auth.schema_migrations (version) VALUES ('20221125140132');
INSERT INTO auth.schema_migrations (version) VALUES ('20221208132122');
INSERT INTO auth.schema_migrations (version) VALUES ('20221215195500');
INSERT INTO auth.schema_migrations (version) VALUES ('20221215195800');
INSERT INTO auth.schema_migrations (version) VALUES ('20221215195900');
INSERT INTO auth.schema_migrations (version) VALUES ('20230116124310');
INSERT INTO auth.schema_migrations (version) VALUES ('20230116124412');
INSERT INTO auth.schema_migrations (version) VALUES ('20230131181311');
INSERT INTO auth.schema_migrations (version) VALUES ('20230322519590');
INSERT INTO auth.schema_migrations (version) VALUES ('20230402418590');
INSERT INTO auth.schema_migrations (version) VALUES ('20230411005111');
INSERT INTO auth.schema_migrations (version) VALUES ('20230508135423');
INSERT INTO auth.schema_migrations (version) VALUES ('20230523124323');
INSERT INTO auth.schema_migrations (version) VALUES ('20230818113222');
INSERT INTO auth.schema_migrations (version) VALUES ('20230914180801');
INSERT INTO auth.schema_migrations (version) VALUES ('20231027141322');
INSERT INTO auth.schema_migrations (version) VALUES ('20231114161723');
INSERT INTO auth.schema_migrations (version) VALUES ('20231117164230');
INSERT INTO auth.schema_migrations (version) VALUES ('20240115144230');
INSERT INTO auth.schema_migrations (version) VALUES ('20240214120130');
INSERT INTO auth.schema_migrations (version) VALUES ('20240306115329');
INSERT INTO auth.schema_migrations (version) VALUES ('20240314092811');
INSERT INTO auth.schema_migrations (version) VALUES ('20240427152123');
INSERT INTO auth.schema_migrations (version) VALUES ('20240612123726');
INSERT INTO auth.schema_migrations (version) VALUES ('20240729123726');
INSERT INTO auth.schema_migrations (version) VALUES ('20240802193726');
INSERT INTO auth.schema_migrations (version) VALUES ('20240806073726');
INSERT INTO auth.schema_migrations (version) VALUES ('20241009103726');
INSERT INTO auth.schema_migrations (version) VALUES ('20250717082212');
INSERT INTO auth.schema_migrations (version) VALUES ('20250731150234');
INSERT INTO auth.schema_migrations (version) VALUES ('20250804100000');
INSERT INTO auth.schema_migrations (version) VALUES ('20250901200500');
INSERT INTO auth.schema_migrations (version) VALUES ('20250903112500');
INSERT INTO auth.schema_migrations (version) VALUES ('20250904133000');
INSERT INTO auth.schema_migrations (version) VALUES ('20250925093508');
INSERT INTO auth.schema_migrations (version) VALUES ('20251007112900');
INSERT INTO auth.schema_migrations (version) VALUES ('20251104100000');
INSERT INTO auth.schema_migrations (version) VALUES ('20251111201300');
INSERT INTO auth.schema_migrations (version) VALUES ('20251201000000');
INSERT INTO auth.schema_migrations (version) VALUES ('20260115000000');
INSERT INTO auth.schema_migrations (version) VALUES ('20260121000000');
INSERT INTO auth.schema_migrations (version) VALUES ('20260219120000');
INSERT INTO auth.schema_migrations (version) VALUES ('20260302000000');


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: webauthn_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: app_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.app_events (id, user_id, event_name, properties, created_at) VALUES ('59bc0fcd-795c-4146-a89a-2cb3f95b3cf3', '68c2027e-dc87-4dad-b817-8b039091e41f', 'profile_shared', '{}', '2026-03-21 17:03:43.411126+00');
INSERT INTO public.app_events (id, user_id, event_name, properties, created_at) VALUES ('18c2bd7f-3aae-4d78-ab19-1e6de78c0d07', '404db5ec-6407-4748-8b7b-43ec6cd244f2', 'profile_shared', '{}', '2026-03-23 16:07:48.615745+00');


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('45468344-0fe8-4889-8549-4174a01ebfb4', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Dodge ram', '+233244254396', '', NULL, 2, '2026-05-05 20:56:04.582856+00', NULL, '2026-05-05 20:47:19.993307+00', '2026-05-05 20:56:04.582856+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('8710c88a-8076-45f6-b9bb-5f162cd5547a', '68c2027e-dc87-4dad-b817-8b039091e41f', 'kojo', '+233591003237', 'abeka', NULL, 1, '2026-03-21 17:07:58.92572+00', NULL, '2026-03-21 17:07:57.718086+00', '2026-03-21 17:07:58.92572+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('ceb4a972-2807-401e-81b8-3dbe4c9b84cf', '68c2027e-dc87-4dad-b817-8b039091e41f', 'door customer', '+233550890649', 'madina estate Presbyterian Church', NULL, 2, '2026-03-22 21:49:37.285975+00', NULL, '2026-03-22 21:41:06.579798+00', '2026-03-22 21:49:37.285975+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('b5e28b6a-7107-4f01-a8c9-aaafe60f95a5', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Hyundai sonata', '+233247345850', 'ashaman', NULL, 1, '2026-03-22 21:52:42.867506+00', NULL, '2026-03-22 21:52:39.398814+00', '2026-03-22 21:52:42.867506+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('f6d0d84d-19ca-4ec0-a364-b02f12ebdaa4', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', 'Delali', '+233244412931', 'East Legon', NULL, 2, '2026-03-22 22:14:06.444749+00', NULL, '2026-03-20 23:37:42.381776+00', '2026-03-22 22:14:06.444749+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('3f320e5e-d807-428b-a611-33e53f0b1b3f', '68c2027e-dc87-4dad-b817-8b039091e41f', 'car dealer tema', '+233244231377', 'tema', NULL, 1, '2026-03-23 14:06:31.488746+00', NULL, '2026-03-23 14:06:27.169547+00', '2026-03-23 14:06:31.488746+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('12ac3f46-17ce-4a9d-8df4-bdbf1ef299f6', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', 'DANIEL', '+233244573211', 'Mystro Empire Villa', NULL, 1, '2026-03-23 22:13:59.864742+00', NULL, '2026-03-23 22:13:57.176463+00', '2026-03-23 22:13:59.864742+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('5ca74fc9-1c66-489f-a1d8-3b9870f46f85', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', 'MR Cymone', '+233243118151', 'Korlebu Hospital', NULL, 1, '2026-03-26 22:31:28.963974+00', NULL, '2026-03-26 22:31:27.765193+00', '2026-03-26 22:31:28.963974+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('e228642b-5d10-480f-8af0-84cbdd110766', '68c2027e-dc87-4dad-b817-8b039091e41f', 'spintex road coca-cola.', '+233248643119', 'spintex road', NULL, 1, '2026-05-11 14:01:29.613715+00', NULL, '2026-05-11 14:01:28.036574+00', '2026-05-11 14:01:29.613715+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('67db9e7b-57bd-4a78-8300-8db6e11e79da', '68c2027e-dc87-4dad-b817-8b039091e41f', 'DG of drink company Santa Maria', '+233592551627', 'santa maria', NULL, 3, '2026-03-27 19:25:35.380871+00', NULL, '2026-03-27 19:23:10.777134+00', '2026-03-27 19:25:35.380871+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('6d6d936d-beee-43b7-afc1-4b9d045a93d8', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Mr xx', '+233243158215', 'keta', NULL, 1, '2026-03-27 19:35:41.846486+00', NULL, '2026-03-27 19:35:40.731228+00', '2026-03-27 19:35:41.846486+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('3959e4ea-1566-4c99-8e32-e77923354360', '68c2027e-dc87-4dad-b817-8b039091e41f', 'tarkwa customer', '+233246243420', 'tarkwa', NULL, 1, '2026-03-30 11:29:30.155036+00', NULL, '2026-03-30 11:29:28.883102+00', '2026-03-30 11:29:30.155036+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('0b45b1ac-8968-4871-9c07-825274eed89f', '68c2027e-dc87-4dad-b817-8b039091e41f', 'arhim', '+233243871428', 'kasoa budubram', NULL, 1, '2026-03-30 11:31:32.890654+00', NULL, '2026-03-30 11:31:31.850868+00', '2026-03-30 11:31:32.890654+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('ac0ad37c-102a-4b13-a01b-7fd26c1be4aa', '68c2027e-dc87-4dad-b817-8b039091e41f', 'castumer', '+233244145326', 'pigfam', NULL, 1, '2026-03-31 12:42:09.706763+00', NULL, '2026-03-31 12:42:08.564159+00', '2026-03-31 12:42:09.706763+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('c951c63f-6eb5-4682-a639-9b328d892591', '68c2027e-dc87-4dad-b817-8b039091e41f', 'ford 150 2023 model', '+233246621856', 'tema community 12', NULL, 1, '2026-03-31 20:34:08.671751+00', NULL, '2026-03-31 20:34:06.958159+00', '2026-03-31 20:34:08.671751+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('420322ae-4331-4fd3-8d70-f598705f7f2a', '68c2027e-dc87-4dad-b817-8b039091e41f', 'customer inconu', '+233245639944', 'West Will more', NULL, 1, '2026-05-11 14:03:53.75929+00', NULL, '2026-05-11 14:03:52.538607+00', '2026-05-11 14:03:53.75929+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('c9ce5406-8ed5-46b3-8795-0d48ab2c6f10', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Ford explorer', '+233208738798', 'new town', NULL, 2, '2026-04-01 14:15:36.847197+00', NULL, '2026-04-01 14:07:43.37301+00', '2026-04-01 14:15:36.847197+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('95624bad-b662-4aeb-a234-e698340a82d5', '68c2027e-dc87-4dad-b817-8b039091e41f', 'old customer push to start elentra', '+233246680050', 'botiarno', NULL, 1, '2026-04-05 09:02:18.458616+00', NULL, '2026-04-05 09:02:17.327675+00', '2026-04-05 09:02:18.458616+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('2187f2e2-78f2-4030-8dce-091509d44f97', '68c2027e-dc87-4dad-b817-8b039091e41f', 'estate', '+233244275554', 'east legon', NULL, 1, '2026-04-09 20:01:13.963851+00', NULL, '2026-04-09 20:01:12.52272+00', '2026-04-09 20:01:13.963851+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('21222473-a8cd-4254-98c1-bd63559e7f29', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Salomon control board', '+233242509322', 'tema', NULL, 2, '2026-04-20 19:57:12.249547+00', NULL, '2026-04-02 16:34:36.743234+00', '2026-04-20 19:57:12.249547+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('4e0bcdd0-799f-4809-8da2-4ddd46dff97a', '68c2027e-dc87-4dad-b817-8b039091e41f', 'sidik', '+233244313132', 'Ghana tershary education', NULL, 1, '2026-04-26 06:45:49.850462+00', NULL, '2026-04-26 06:45:48.566593+00', '2026-04-26 06:45:49.850462+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('7da885e4-866d-4989-8af3-efc0ccc1e575', '68c2027e-dc87-4dad-b817-8b039091e41f', 'ras swedru', '+233205905320', 'swedru', NULL, 1, '2026-04-29 16:32:04.62385+00', NULL, '2026-04-29 16:32:03.4385+00', '2026-04-29 16:32:04.62385+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('d9fcee8b-1121-475b-b2d3-5e3c63b5f9a3', '68c2027e-dc87-4dad-b817-8b039091e41f', 'sengo', '+233544604103', 'nusuobri', NULL, 1, '2026-04-29 16:34:04.199365+00', NULL, '2026-04-29 16:34:03.110112+00', '2026-04-29 16:34:04.199365+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('f42922ce-88cb-44bf-af2c-eb5f9e9caa22', '68c2027e-dc87-4dad-b817-8b039091e41f', 'EVEN', '+233544009568', 'cantonment', NULL, 1, '2026-05-02 17:02:00.781149+00', NULL, '2026-05-02 17:01:59.635039+00', '2026-05-02 17:02:00.781149+00');
INSERT INTO public.customers (id, user_id, full_name, phone_number, location, notes, total_jobs, last_job_at, deleted_at, created_at, updated_at) VALUES ('a8e97234-857e-4972-8d22-bd80e0e56a84', '68c2027e-dc87-4dad-b817-8b039091e41f', 'tarkwa customer GMC', '+233246701209', 'tarkwa', NULL, 1, '2026-05-04 15:17:47.02588+00', NULL, '2026-05-04 15:17:45.736938+00', '2026-05-04 15:17:47.02588+00');


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users (id, auth_id, full_name, phone_number, email, role, status, profile_slug, last_seen_at, created_at, updated_at) VALUES ('16f544a9-a18e-4f12-9637-69f8186a715d', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', 'Abel Dossa', '+233530823904', NULL, 'technician', 'pending', 'abel-dossa', NULL, '2026-03-20 23:19:44.402037+00', '2026-03-20 23:19:44.402037+00');
INSERT INTO public.users (id, auth_id, full_name, phone_number, email, role, status, profile_slug, last_seen_at, created_at, updated_at) VALUES ('2adfb7a3-907a-4f64-a8c0-bd89acd42c24', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', 'John DODO', '+233531307502', NULL, 'technician', 'pending', 'john-dodo', NULL, '2026-03-20 23:37:54.389401+00', '2026-03-20 23:37:54.389401+00');
INSERT INTO public.users (id, auth_id, full_name, phone_number, email, role, status, profile_slug, last_seen_at, created_at, updated_at) VALUES ('98333dac-79e0-402d-bbb6-7ea44ad33bc7', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Jeremiah Kojo Aguidi', '+233535891956', NULL, 'technician', 'pending', 'jeremiah-kojo-aguidi', NULL, '2026-03-21 10:54:09.178442+00', '2026-03-21 10:54:09.178442+00');
INSERT INTO public.users (id, auth_id, full_name, phone_number, email, role, status, profile_slug, last_seen_at, created_at, updated_at) VALUES ('4b34f6e7-2219-4460-b068-0504b99476c1', '404db5ec-6407-4748-8b7b-43ec6cd244f2', 'Emmanuel Degbey', '+233549628060', NULL, 'technician', 'pending', 'emmanuel-degbey', NULL, '2026-03-23 16:05:23.085889+00', '2026-03-23 16:05:23.085889+00');


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('348d9b55-d4a5-4672-b161-8d341c8da5a9', '16f544a9-a18e-4f12-9637-69f8186a715d', 'f6d0d84d-19ca-4ec0-a364-b02f12ebdaa4', 'car_lock_programming', '2026-03-20', 'East Legon', NULL, NULL, 'He rose', 450.00, false, NULL, 'synced', false, '2026-03-20 23:37:43.812969+00', '2026-03-20 23:37:43.812969+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('2f8d58b4-f622-4116-b63d-7abc72362561', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '8710c88a-8076-45f6-b9bb-5f162cd5547a', 'car_lock_programming', '2026-03-20', 'abeka', NULL, NULL, 'key programming', 500.00, false, NULL, 'synced', false, '2026-03-21 17:07:58.92572+00', '2026-03-21 17:07:58.92572+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('544282a7-b673-4655-adc4-93dfec3a9c47', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'ceb4a972-2807-401e-81b8-3dbe4c9b84cf', 'door_lock_installation', '2026-03-20', 'madina estate Presbyterian Church', NULL, NULL, 'smart lock system installation', 350.00, false, NULL, 'synced', false, '2026-03-22 21:41:10.874844+00', '2026-03-22 21:41:10.874844+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('fd796b42-1634-48c3-8e54-fd7498ec3217', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'ceb4a972-2807-401e-81b8-3dbe4c9b84cf', 'door_lock_installation', '2026-03-20', 'madina estate Presbyterian Church', NULL, NULL, 'smart lock installation', 750.00, false, NULL, 'synced', false, '2026-03-22 21:49:37.285975+00', '2026-03-22 21:49:37.285975+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('6e48e82b-889c-4b9e-b9a8-f5584bcaba13', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'b5e28b6a-7107-4f01-a8c9-aaafe60f95a5', 'car_lock_programming', '2026-03-20', 'ashaman', NULL, NULL, 'smart key programming', 800.00, false, NULL, 'synced', false, '2026-03-22 21:52:42.867506+00', '2026-03-22 21:52:42.867506+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('1eacfb05-d15c-41bf-bc17-bc87472285b8', '16f544a9-a18e-4f12-9637-69f8186a715d', 'f6d0d84d-19ca-4ec0-a364-b02f12ebdaa4', 'car_lock_programming', '2026-03-22', 'East Legon', NULL, NULL, '', 240.00, false, NULL, 'synced', false, '2026-03-22 22:14:06.444749+00', '2026-03-22 22:14:06.444749+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('a33152d3-929e-4b80-96a1-809cd3199d62', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '3f320e5e-d807-428b-a611-33e53f0b1b3f', 'car_lock_programming', '2026-03-23', 'tema', NULL, NULL, 'smart key programming for Honda crv', 900.00, false, NULL, 'synced', false, '2026-03-23 14:06:31.488746+00', '2026-03-23 14:06:31.488746+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('c1804a96-a963-453c-81be-b42249cdf49a', '2adfb7a3-907a-4f64-a8c0-bd89acd42c24', '12ac3f46-17ce-4a9d-8df4-bdbf1ef299f6', 'smart_lock_installation', '2026-03-23', 'Mystro Empire Villa', NULL, NULL, 'PUSH TO START SYSTEM INSTALLATION.', 1900.00, false, NULL, 'synced', false, '2026-03-23 22:13:59.864742+00', '2026-03-26 22:23:09.902701+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('0001d41f-68b6-4037-8a10-bbed3d1799d3', '2adfb7a3-907a-4f64-a8c0-bd89acd42c24', '5ca74fc9-1c66-489f-a1d8-3b9870f46f85', 'car_lock_programming', '2026-03-25', 'Korlebu Hospital', NULL, NULL, 'Honda Remote key', 600.00, false, NULL, 'synced', false, '2026-03-26 22:31:28.963974+00', '2026-03-26 22:31:28.963974+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('f2144c29-c681-46d6-b24d-540a161813c4', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '67db9e7b-57bd-4a78-8300-8db6e11e79da', 'car_lock_programming', '2026-03-26', 'santa maria', NULL, NULL, 'trucking system installation  for ford explorer 2019', 650.00, false, NULL, 'synced', false, '2026-03-27 19:23:12.30555+00', '2026-03-27 19:24:37.146336+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('ab815a53-b7b6-4e44-92eb-23c0a9366d79', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '67db9e7b-57bd-4a78-8300-8db6e11e79da', 'car_lock_programming', '2026-03-26', 'santa maria', NULL, NULL, 'trucking system installation', 650.00, false, NULL, 'synced', false, '2026-03-27 19:24:37.146336+00', '2026-03-27 19:24:37.146336+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('8e9a5c2d-02c0-42cf-b1ed-b27876282b71', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '67db9e7b-57bd-4a78-8300-8db6e11e79da', 'car_lock_programming', '2026-03-27', 'santa maria', NULL, NULL, 'smart key programming for ford explorer 2019', 1500.00, false, NULL, 'synced', false, '2026-03-27 19:25:35.380871+00', '2026-03-27 19:25:35.380871+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('9c0557c1-ffdb-4805-b186-79b110c78d5a', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '6d6d936d-beee-43b7-afc1-4b9d045a93d8', 'door_lock_repair', '2026-03-18', 'keta', NULL, NULL, 'smart lock configuration for 6 locks', 2000.00, false, NULL, 'synced', false, '2026-03-27 19:35:41.846486+00', '2026-03-27 19:35:41.846486+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('b1cca269-ec7b-47bd-8fa9-9b5631bcf3f2', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '3959e4ea-1566-4c99-8e32-e77923354360', 'car_lock_programming', '2026-03-30', 'tarkwa', NULL, NULL, 'shel change and spare key programming', 600.00, false, NULL, 'synced', false, '2026-03-30 11:29:30.155036+00', '2026-03-30 11:29:30.155036+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('67a90873-03f2-4dea-99f2-37a5227d0e2e', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '0b45b1ac-8968-4871-9c07-825274eed89f', 'car_lock_programming', '2026-03-30', 'kasoa budubram', NULL, NULL, 'spare key programming for Toyota voxy', 1100.00, false, NULL, 'synced', false, '2026-03-30 11:31:32.890654+00', '2026-03-30 11:31:32.890654+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('0eb48fdf-5064-4833-8cd3-6a1b22c2089d', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'ac0ad37c-102a-4b13-a01b-7fd26c1be4aa', 'car_lock_programming', '2026-03-31', 'pigfam', NULL, NULL, 'key reprogram', 200.00, false, NULL, 'synced', false, '2026-03-31 12:42:09.706763+00', '2026-03-31 12:42:09.706763+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('c8e1f0f6-070a-4002-9025-dcb27718ad49', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'c951c63f-6eb5-4682-a639-9b328d892591', 'car_lock_programming', '2026-03-31', 'tema community 12', NULL, NULL, 'key programming for ford 150 2023 model', 800.00, false, NULL, 'synced', false, '2026-03-31 20:34:08.671751+00', '2026-03-31 20:34:08.671751+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('a8c419a1-4fad-44ed-8b3c-3cbf8681f448', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'c9ce5406-8ed5-46b3-8795-0d48ab2c6f10', 'car_lock_programming', '2026-03-18', 'new town', NULL, NULL, 'push to start system installation', 900.00, false, NULL, 'synced', false, '2026-04-01 14:07:44.573846+00', '2026-04-01 14:07:44.573846+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('965f9576-684f-455f-8c47-2baedcd175b4', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'c9ce5406-8ed5-46b3-8795-0d48ab2c6f10', 'car_lock_programming', '2026-04-01', 'new town', NULL, NULL, 'spare key programming push to start', 600.00, false, NULL, 'synced', false, '2026-04-01 14:15:36.847197+00', '2026-04-01 14:15:36.847197+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('78bc8c83-b686-423b-8c01-bc08483d3435', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '21222473-a8cd-4254-98c1-bd63559e7f29', 'car_lock_programming', '2026-04-02', 'tema', NULL, NULL, 'electrical system checking', 600.00, false, NULL, 'synced', false, '2026-04-02 16:34:38.091852+00', '2026-04-02 16:34:38.091852+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('2f313a75-c0f3-41b8-a433-135c4e4f01c3', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '95624bad-b662-4aeb-a234-e698340a82d5', 'car_lock_programming', '2026-04-03', 'botiarno', NULL, NULL, 'push to start system change', 600.00, false, NULL, 'synced', false, '2026-04-05 09:02:18.458616+00', '2026-04-05 09:02:18.458616+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('a5f3efd9-31ea-43c0-a174-57e773721a23', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '2187f2e2-78f2-4030-8dce-091509d44f97', 'door_lock_installation', '2026-04-09', 'east legon', NULL, NULL, 'smart lock installation', 600.00, false, NULL, 'synced', false, '2026-04-09 20:01:13.963851+00', '2026-04-09 20:01:13.963851+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('b199e76d-5331-42a8-a3df-627799962fcd', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '21222473-a8cd-4254-98c1-bd63559e7f29', 'car_lock_programming', '2026-04-14', 'hongkong', NULL, NULL, 'control board and cluster programming', 1800.00, false, NULL, 'synced', false, '2026-04-20 19:57:12.249547+00', '2026-04-20 19:57:12.249547+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('b4d072e1-75cc-490f-a078-f45a627b4f89', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '4e0bcdd0-799f-4809-8da2-4ddd46dff97a', 'door_lock_installation', '2026-04-16', 'Ghana tershary education', NULL, NULL, '12 Smart lock installation', 4000.00, false, NULL, 'synced', false, '2026-04-26 06:45:49.850462+00', '2026-04-26 06:45:49.850462+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('7c9ddbb8-400f-4ba1-98b6-88ebde5c9514', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '7da885e4-866d-4989-8af3-efc0ccc1e575', 'car_lock_programming', '2026-04-28', 'swedru', NULL, NULL, 'Smart key programming', 2000.00, false, NULL, 'synced', false, '2026-04-29 16:32:04.62385+00', '2026-04-29 16:32:04.62385+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('d15d9e64-0bbe-47b2-9ef0-91f6f2c68dd6', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'd9fcee8b-1121-475b-b2d3-5e3c63b5f9a3', 'door_lock_installation', '2026-04-27', 'nusuobri', NULL, NULL, 'camera installation', 300.00, false, NULL, 'synced', false, '2026-04-29 16:34:04.199365+00', '2026-04-29 16:34:04.199365+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('268c2133-b1e3-4314-839c-fade29163a1e', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'f42922ce-88cb-44bf-af2c-eb5f9e9caa22', 'door_lock_installation', '2026-05-02', 'cantonment', NULL, NULL, 'lock installation and gateway installation. 800 for one', 2150.00, false, NULL, 'synced', false, '2026-05-02 17:02:00.781149+00', '2026-05-02 17:02:00.781149+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('eff125f2-00c7-4c21-965d-899d3dfb5c6b', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'a8e97234-857e-4972-8d22-bd80e0e56a84', 'car_lock_programming', '2026-05-04', 'tarkwa', NULL, NULL, 'spare key programming for GMC terrain 2019', 1100.00, false, NULL, 'synced', false, '2026-05-04 15:17:47.02588+00', '2026-05-04 15:17:47.02588+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('0e157b26-018d-4831-b3dd-034bfee7c3ae', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '45468344-0fe8-4889-8549-4174a01ebfb4', 'car_lock_programming', '2026-05-05', '', NULL, NULL, '', NULL, false, NULL, 'synced', true, '2026-05-05 20:47:21.331751+00', '2026-05-05 20:47:53.973325+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('c336a5d1-74fc-41f1-a3fd-31ec90713c22', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '45468344-0fe8-4889-8549-4174a01ebfb4', 'car_lock_programming', '2026-05-05', 'ablekuma', NULL, NULL, 'Key programming', 400.00, false, NULL, 'synced', false, '2026-05-05 20:56:04.582856+00', '2026-05-05 20:56:04.582856+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('40b02ff0-b75b-4575-9ddc-6e78378e8c34', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'e228642b-5d10-480f-8af0-84cbdd110766', 'car_lock_programming', '2026-05-11', 'spintex road', NULL, NULL, 'key programin ( spare key)', 500.00, false, NULL, 'synced', false, '2026-05-11 14:01:29.613715+00', '2026-05-11 14:01:29.613715+00');
INSERT INTO public.jobs (id, user_id, customer_id, service_type, job_date, location, latitude, longitude, notes, amount_charged, follow_up_sent, follow_up_sent_at, sync_status, is_archived, created_at, updated_at) VALUES ('1994a958-26ad-4589-b7bb-caed0e7c6b84', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '420322ae-4331-4fd3-8d70-f598705f7f2a', 'door_lock_repair', '2026-05-10', 'West Will more', NULL, NULL, 'door open for Kia optima', 100.00, false, NULL, 'synced', false, '2026-05-11 14:03:53.75929+00', '2026-05-11 14:03:53.75929+00');


--
-- Data for Name: correction_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: follow_ups; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: knowledge_notes; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.profiles (id, user_id, display_name, bio, photo_url, services, whatsapp_number, is_public, profile_url, created_at, updated_at) VALUES ('dd9baa7f-7c54-4711-a259-00c7215951e3', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', 'John DODO', '', '', '{car_lock_programming,door_lock_repair}', '+233531307502', true, 'john-dodo', '2026-03-20 23:37:54.654978+00', '2026-03-20 23:37:54.654978+00');
INSERT INTO public.profiles (id, user_id, display_name, bio, photo_url, services, whatsapp_number, is_public, profile_url, created_at, updated_at) VALUES ('7a1fcd30-10fe-44bf-bc6d-c28945b4f0b7', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', 'Abel Dossa', '', 'https://ifzpdizxitlvjbmzozew.supabase.co/storage/v1/object/public/profile-photos/273649c3-15bc-4026-b9fb-a7f44aa0ec16/profile.png?t=1774049926378', '{car_lock_programming,door_lock_installation,door_lock_repair,smart_lock_installation}', '0530823904', true, 'abel-dossa', '2026-03-20 23:19:44.818114+00', '2026-03-20 23:38:52.778667+00');
INSERT INTO public.profiles (id, user_id, display_name, bio, photo_url, services, whatsapp_number, is_public, profile_url, created_at, updated_at) VALUES ('38c80bb5-86d9-4bcf-8868-dc9b0d19520d', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Jeremiah Kojo Aguidi', 'key programin 
alarm installation 
trucking installation 
smart lock 🔐 installation 
push to start system installation 
.......etc', 'https://ifzpdizxitlvjbmzozew.supabase.co/storage/v1/object/public/profile-photos/68c2027e-dc87-4dad-b817-8b039091e41f/profile.jpg?t=1774216669811', '{car_lock_programming,door_lock_installation,door_lock_repair,smart_lock_installation}', '0535891956', true, 'jeremiah-kojo-aguidi', '2026-03-21 10:54:09.645672+00', '2026-03-22 21:58:08.983318+00');
INSERT INTO public.profiles (id, user_id, display_name, bio, photo_url, services, whatsapp_number, is_public, profile_url, created_at, updated_at) VALUES ('6a3c7016-0739-4c22-ad19-840c92b66241', '404db5ec-6407-4748-8b7b-43ec6cd244f2', 'Emmanuel Degbey', '', 'https://ifzpdizxitlvjbmzozew.supabase.co/storage/v1/object/public/profile-photos/404db5ec-6407-4748-8b7b-43ec6cd244f2/profile.jpg?t=1774282104492', '{car_lock_programming,smart_lock_installation}', '0549628060', true, 'emmanuel-degbey', '2026-03-23 16:05:23.526472+00', '2026-03-23 16:08:51.282674+00');


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116024918, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116045059, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116050929, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116051442, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116212300, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116213355, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116213934, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211116214523, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211122062447, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211124070109, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211202204204, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211202204605, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211210212804, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20211228014915, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220107221237, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220228202821, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220312004840, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220603231003, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220603232444, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220615214548, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220712093339, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220908172859, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20220916233421, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230119133233, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230128025114, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230128025212, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230227211149, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230228184745, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230308225145, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20230328144023, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20231018144023, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20231204144023, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20231204144024, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20231204144025, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240108234812, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240109165339, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240227174441, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240311171622, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240321100241, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240401105812, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240418121054, '2026-03-17 22:27:41');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240523004032, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240618124746, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240801235015, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240805133720, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240827160934, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240919163303, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20240919163305, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241019105805, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241030150047, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241108114728, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241121104152, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241130184212, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241220035512, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241220123912, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20241224161212, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250107150512, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250110162412, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250123174212, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250128220012, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250506224012, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250523164012, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250714121412, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20250905041441, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20251103001201, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20251120212548, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20251120215549, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20260218120000, '2026-03-17 22:27:42');
INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES (20260326120000, '2026-05-13 00:29:26');


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--



--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

INSERT INTO storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) VALUES ('profile-photos', 'profile-photos', NULL, '2026-03-19 21:22:32.781017+00', '2026-03-19 21:22:32.781017+00', true, false, 5242880, '{image/jpeg,image/png,image/webp}', NULL, 'STANDARD');
INSERT INTO storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) VALUES ('note-photos', 'note-photos', NULL, '2026-03-19 21:22:32.781017+00', '2026-03-19 21:22:32.781017+00', true, false, 5242880, '{image/jpeg,image/png,image/webp}', NULL, 'STANDARD');


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (0, 'create-migrations-table', 'e18db593bcde2aca2a408c4d1100f6abba2195df', '2026-03-17 22:27:41.243948');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (1, 'initialmigration', '6ab16121fbaa08bbd11b712d05f358f9b555d777', '2026-03-17 22:27:41.285719');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (2, 'storage-schema', 'f6a1fa2c93cbcd16d4e487b362e45fca157a8dbd', '2026-03-17 22:27:41.290776');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (3, 'pathtoken-column', '2cb1b0004b817b29d5b0a971af16bafeede4b70d', '2026-03-17 22:27:41.34348');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (4, 'add-migrations-rls', '427c5b63fe1c5937495d9c635c263ee7a5905058', '2026-03-17 22:27:41.403434');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (5, 'add-size-functions', '79e081a1455b63666c1294a440f8ad4b1e6a7f84', '2026-03-17 22:27:41.407566');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (6, 'change-column-name-in-get-size', 'ded78e2f1b5d7e616117897e6443a925965b30d2', '2026-03-17 22:27:41.413393');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (7, 'add-rls-to-buckets', 'e7e7f86adbc51049f341dfe8d30256c1abca17aa', '2026-03-17 22:27:41.419592');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (8, 'add-public-to-buckets', 'fd670db39ed65f9d08b01db09d6202503ca2bab3', '2026-03-17 22:27:41.424073');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (9, 'fix-search-function', 'af597a1b590c70519b464a4ab3be54490712796b', '2026-03-17 22:27:41.429453');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (10, 'search-files-search-function', 'b595f05e92f7e91211af1bbfe9c6a13bb3391e16', '2026-03-17 22:27:41.434211');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (11, 'add-trigger-to-auto-update-updated_at-column', '7425bdb14366d1739fa8a18c83100636d74dcaa2', '2026-03-17 22:27:41.439419');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (12, 'add-automatic-avif-detection-flag', '8e92e1266eb29518b6a4c5313ab8f29dd0d08df9', '2026-03-17 22:27:41.445735');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (13, 'add-bucket-custom-limits', 'cce962054138135cd9a8c4bcd531598684b25e7d', '2026-03-17 22:27:41.449937');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (14, 'use-bytes-for-max-size', '941c41b346f9802b411f06f30e972ad4744dad27', '2026-03-17 22:27:41.454623');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (15, 'add-can-insert-object-function', '934146bc38ead475f4ef4b555c524ee5d66799e5', '2026-03-17 22:27:41.485325');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (16, 'add-version', '76debf38d3fd07dcfc747ca49096457d95b1221b', '2026-03-17 22:27:41.489399');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (17, 'drop-owner-foreign-key', 'f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101', '2026-03-17 22:27:41.493074');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (18, 'add_owner_id_column_deprecate_owner', 'e7a511b379110b08e2f214be852c35414749fe66', '2026-03-17 22:27:41.497272');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (19, 'alter-default-value-objects-id', '02e5e22a78626187e00d173dc45f58fa66a4f043', '2026-03-17 22:27:41.505394');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (20, 'list-objects-with-delimiter', 'cd694ae708e51ba82bf012bba00caf4f3b6393b7', '2026-03-17 22:27:41.509225');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (21, 's3-multipart-uploads', '8c804d4a566c40cd1e4cc5b3725a664a9303657f', '2026-03-17 22:27:41.514208');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (22, 's3-multipart-uploads-big-ints', '9737dc258d2397953c9953d9b86920b8be0cdb73', '2026-03-17 22:27:41.528732');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (23, 'optimize-search-function', '9d7e604cddc4b56a5422dc68c9313f4a1b6f132c', '2026-03-17 22:27:41.540311');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (24, 'operation-function', '8312e37c2bf9e76bbe841aa5fda889206d2bf8aa', '2026-03-17 22:27:41.544344');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (25, 'custom-metadata', 'd974c6057c3db1c1f847afa0e291e6165693b990', '2026-03-17 22:27:41.548068');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (26, 'objects-prefixes', '215cabcb7f78121892a5a2037a09fedf9a1ae322', '2026-03-17 22:27:41.552263');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (27, 'search-v2', '859ba38092ac96eb3964d83bf53ccc0b141663a6', '2026-03-17 22:27:41.556867');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (28, 'object-bucket-name-sorting', 'c73a2b5b5d4041e39705814fd3a1b95502d38ce4', '2026-03-17 22:27:41.561517');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (29, 'create-prefixes', 'ad2c1207f76703d11a9f9007f821620017a66c21', '2026-03-17 22:27:41.566054');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (30, 'update-object-levels', '2be814ff05c8252fdfdc7cfb4b7f5c7e17f0bed6', '2026-03-17 22:27:41.56977');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (31, 'objects-level-index', 'b40367c14c3440ec75f19bbce2d71e914ddd3da0', '2026-03-17 22:27:41.573316');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (32, 'backward-compatible-index-on-objects', 'e0c37182b0f7aee3efd823298fb3c76f1042c0f7', '2026-03-17 22:27:41.57735');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (33, 'backward-compatible-index-on-prefixes', 'b480e99ed951e0900f033ec4eb34b5bdcb4e3d49', '2026-03-17 22:27:41.581826');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (34, 'optimize-search-function-v1', 'ca80a3dc7bfef894df17108785ce29a7fc8ee456', '2026-03-17 22:27:41.587734');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (35, 'add-insert-trigger-prefixes', '458fe0ffd07ec53f5e3ce9df51bfdf4861929ccc', '2026-03-17 22:27:41.592691');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (36, 'optimise-existing-functions', '6ae5fca6af5c55abe95369cd4f93985d1814ca8f', '2026-03-17 22:27:41.596941');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (37, 'add-bucket-name-length-trigger', '3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1', '2026-03-17 22:27:41.603689');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (38, 'iceberg-catalog-flag-on-buckets', '02716b81ceec9705aed84aa1501657095b32e5c5', '2026-03-17 22:27:41.613639');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (39, 'add-search-v2-sort-support', '6706c5f2928846abee18461279799ad12b279b78', '2026-03-17 22:27:41.633382');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (40, 'fix-prefix-race-conditions-optimized', '7ad69982ae2d372b21f48fc4829ae9752c518f6b', '2026-03-17 22:27:41.638238');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (41, 'add-object-level-update-trigger', '07fcf1a22165849b7a029deed059ffcde08d1ae0', '2026-03-17 22:27:41.642314');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (42, 'rollback-prefix-triggers', '771479077764adc09e2ea2043eb627503c034cd4', '2026-03-17 22:27:41.646688');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (43, 'fix-object-level', '84b35d6caca9d937478ad8a797491f38b8c2979f', '2026-03-17 22:27:41.651351');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (44, 'vector-bucket-type', '99c20c0ffd52bb1ff1f32fb992f3b351e3ef8fb3', '2026-03-17 22:27:41.655443');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (45, 'vector-buckets', '049e27196d77a7cb76497a85afae669d8b230953', '2026-03-17 22:27:41.665199');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (46, 'buckets-objects-grants', 'fedeb96d60fefd8e02ab3ded9fbde05632f84aed', '2026-03-17 22:27:41.682022');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (47, 'iceberg-table-metadata', '649df56855c24d8b36dd4cc1aeb8251aa9ad42c2', '2026-03-17 22:27:41.686686');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (48, 'iceberg-catalog-ids', 'e0e8b460c609b9999ccd0df9ad14294613eed939', '2026-03-17 22:27:41.691729');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (49, 'buckets-objects-grants-postgres', '072b1195d0d5a2f888af6b2302a1938dd94b8b3d', '2026-03-17 22:27:41.711479');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (50, 'search-v2-optimised', '6323ac4f850aa14e7387eb32102869578b5bd478', '2026-03-17 22:27:41.716774');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (51, 'index-backward-compatible-search', '2ee395d433f76e38bcd3856debaf6e0e5b674011', '2026-03-17 22:27:42.210234');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (52, 'drop-not-used-indexes-and-functions', '5cc44c8696749ac11dd0dc37f2a3802075f3a171', '2026-03-17 22:27:42.212042');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (53, 'drop-index-lower-name', 'd0cb18777d9e2a98ebe0bc5cc7a42e57ebe41854', '2026-03-17 22:27:42.227764');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (54, 'drop-index-object-level', '6289e048b1472da17c31a7eba1ded625a6457e67', '2026-03-17 22:27:42.230913');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (55, 'prevent-direct-deletes', '262a4798d5e0f2e7c8970232e03ce8be695d5819', '2026-03-17 22:27:42.232592');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (57, 's3-multipart-uploads-metadata', 'f127886e00d1b374fadbc7c6b31e09336aad5287', '2026-04-11 13:21:47.399403');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (58, 'operation-ergonomics', '00ca5d483b3fe0d522133d9002ccc5df98365120', '2026-04-11 13:21:47.427702');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (56, 'fix-optimized-search-function', 'b823ed1e418101032fa01374edc9a436e54e3ed4', '2026-03-17 22:27:42.238163');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (59, 'drop-unused-functions', '38456f13e39691c2bbb4b5151d0d1cdbabd4a8c4', '2026-05-13 00:29:29.391724');
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (60, 'optimize-existing-functions-again', 'db35e1c91a9201e59f4fef8d972c2f277d68b157', '2026-05-13 00:29:29.45544');


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('310d5874-57ec-49d2-8be2-63b6d537cddc', 'profile-photos', '273649c3-15bc-4026-b9fb-a7f44aa0ec16/profile.png', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', '2026-03-20 23:38:47.440887+00', '2026-03-20 23:38:47.440887+00', '2026-03-20 23:38:47.440887+00', '{"eTag": "\"b41657f6deff173dcce86a364c0b6e1a\"", "size": 200107, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-03-20T23:38:48.000Z", "contentLength": 200107, "httpStatusCode": 200}', 'ea647c0d-425b-408d-8869-6fe2b0b636b0', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('5d0d8b0d-c8b4-4438-bc95-d25d5a985150', 'profile-photos', '68c2027e-dc87-4dad-b817-8b039091e41f/profile.png', '68c2027e-dc87-4dad-b817-8b039091e41f', '2026-03-21 17:04:55.407862+00', '2026-03-21 17:04:55.407862+00', '2026-03-21 17:04:55.407862+00', '{"eTag": "\"e3feda2aeda1eec289885fd5c48e2c0f\"", "size": 50553, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2026-03-21T17:04:56.000Z", "contentLength": 50553, "httpStatusCode": 200}', '0033ab20-df47-49f1-a3c1-39304156cccb', '68c2027e-dc87-4dad-b817-8b039091e41f', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('46845d5b-5640-487c-af9b-4764bcbeadc2', 'profile-photos', '68c2027e-dc87-4dad-b817-8b039091e41f/profile.jpg', '68c2027e-dc87-4dad-b817-8b039091e41f', '2026-03-22 21:57:50.910739+00', '2026-03-22 21:57:50.910739+00', '2026-03-22 21:57:50.910739+00', '{"eTag": "\"51ad8f653b2bc7336899423e947df85e\"", "size": 33995, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-03-22T21:57:51.000Z", "contentLength": 33995, "httpStatusCode": 200}', 'c981a313-5c46-45d6-a357-c762a080eab6', '68c2027e-dc87-4dad-b817-8b039091e41f', '{}');
INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES ('4b688119-3260-4526-87e2-68c161f83672', 'profile-photos', '404db5ec-6407-4748-8b7b-43ec6cd244f2/profile.jpg', '404db5ec-6407-4748-8b7b-43ec6cd244f2', '2026-03-23 16:08:24.724186+00', '2026-03-23 16:08:24.724186+00', '2026-03-23 16:08:24.724186+00', '{"eTag": "\"1a11646945aaaeb95186aecbb10db824\"", "size": 57111, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-03-23T16:08:25.000Z", "contentLength": 57111, "httpStatusCode": 200}', 'f0273fc7-181f-423d-8a9a-74298c33e08d', '404db5ec-6407-4748-8b7b-43ec6cd244f2', '{}');


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: supabase_migrations; Owner: postgres
--

INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260316013206', '{"SET statement_timeout = 0","SET lock_timeout = 0","SET idle_in_transaction_session_timeout = 0","SET client_encoding = ''UTF8''","SET standard_conforming_strings = on","SELECT pg_catalog.set_config(''search_path'', '''', false)","SET check_function_bodies = false","SET xmloption = content","SET client_min_messages = warning","SET row_security = off","COMMENT ON SCHEMA \"public\" IS ''standard public schema''","CREATE EXTENSION IF NOT EXISTS \"citext\" WITH SCHEMA \"public\"","CREATE EXTENSION IF NOT EXISTS \"pg_graphql\" WITH SCHEMA \"graphql\"","CREATE EXTENSION IF NOT EXISTS \"pg_stat_statements\" WITH SCHEMA \"extensions\"","CREATE EXTENSION IF NOT EXISTS \"pgcrypto\" WITH SCHEMA \"extensions\"","CREATE EXTENSION IF NOT EXISTS \"supabase_vault\" WITH SCHEMA \"vault\"","CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\" WITH SCHEMA \"extensions\"","CREATE TYPE \"public\".\"service_type\" AS ENUM (
    ''car_lock_programming'',
    ''door_lock_installation'',
    ''door_lock_repair'',
    ''smart_lock_installation''
)","ALTER TYPE \"public\".\"service_type\" OWNER TO \"postgres\"","CREATE TYPE \"public\".\"sync_status\" AS ENUM (
    ''pending'',
    ''synced'',
    ''failed''
)","ALTER TYPE \"public\".\"sync_status\" OWNER TO \"postgres\"","CREATE TYPE \"public\".\"user_role\" AS ENUM (
    ''technician'',
    ''founding_technician'',
    ''admin''
)","ALTER TYPE \"public\".\"user_role\" OWNER TO \"postgres\"","CREATE TYPE \"public\".\"user_status\" AS ENUM (
    ''pending'',
    ''active'',
    ''suspended''
)","ALTER TYPE \"public\".\"user_status\" OWNER TO \"postgres\"","CREATE OR REPLACE FUNCTION \"public\".\"batch_sync_customers\"(\"p_user_id\" \"uuid\", \"p_customers\" \"jsonb\") RETURNS \"jsonb\"
    LANGUAGE \"plpgsql\" SECURITY DEFINER
    AS $$
DECLARE
  customer_record JSONB;
  new_customer_id UUID;
  synced_customers JSONB := ''[]'';
  failed_customers JSONB := ''[]'';
BEGIN
  FOR customer_record IN SELECT * FROM jsonb_array_elements(p_customers)
  LOOP
    BEGIN
      INSERT INTO customers (id, user_id, full_name, phone_number, location, notes)
      VALUES (
        (customer_record->>''id'')::UUID,
        p_user_id,
        customer_record->>''full_name'',
        customer_record->>''phone_number'',
        customer_record->>''location'',
        customer_record->>''notes''
      )
      ON CONFLICT (user_id, phone_number) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        location = COALESCE(EXCLUDED.location, customers.location),
        notes = COALESCE(EXCLUDED.notes, customers.notes),
        updated_at = NOW()
      RETURNING id INTO new_customer_id;
      
      synced_customers := synced_customers || jsonb_build_object(''local_id'', customer_record->>''id'', ''server_id'', new_customer_id, ''sync_status'', ''synced'');
    EXCEPTION WHEN OTHERS THEN
      failed_customers := failed_customers || jsonb_build_object(''local_id'', customer_record->>''id'', ''error'', SQLERRM);
    END;
  END LOOP;
  RETURN jsonb_build_object(''synced'', synced_customers, ''failed'', failed_customers);
END;
$$","ALTER FUNCTION \"public\".\"batch_sync_customers\"(\"p_user_id\" \"uuid\", \"p_customers\" \"jsonb\") OWNER TO \"postgres\"","CREATE OR REPLACE FUNCTION \"public\".\"batch_sync_jobs\"(\"p_user_id\" \"uuid\", \"p_jobs\" \"jsonb\") RETURNS \"jsonb\"
    LANGUAGE \"plpgsql\" SECURITY DEFINER
    AS $$
DECLARE
  job_record JSONB;
  new_job_id UUID;
  synced_jobs JSONB := ''[]'';
  failed_jobs JSONB := ''[]'';
BEGIN
  FOR job_record IN SELECT * FROM jsonb_array_elements(p_jobs)
  LOOP
    BEGIN
      INSERT INTO jobs (id, user_id, customer_id, service_type, job_date, location, notes, amount_charged, sync_status)
      VALUES (
        (job_record->>''id'')::UUID,
        p_user_id,
        (job_record->>''customer_id'')::UUID,
        (job_record->>''service_type'')::service_type,
        (job_record->>''job_date'')::DATE,
        job_record->>''location'',
        job_record->>''notes'',
        (job_record->>''amount_charged'')::DECIMAL,
        ''synced''
      )
      ON CONFLICT (id) DO UPDATE SET
        sync_status = EXCLUDED.sync_status,
        updated_at = NOW()
      RETURNING id INTO new_job_id;
      
      synced_jobs := synced_jobs || jsonb_build_object(''local_id'', job_record->>''local_id'', ''server_id'', new_job_id, ''sync_status'', ''synced'');
    EXCEPTION WHEN OTHERS THEN
      failed_jobs := failed_jobs || jsonb_build_object(''local_id'', job_record->>''local_id'', ''error'', SQLERRM);
    END;
  END LOOP;
  RETURN jsonb_build_object(''synced'', synced_jobs, ''failed'', failed_jobs);
END;
$$","ALTER FUNCTION \"public\".\"batch_sync_jobs\"(\"p_user_id\" \"uuid\", \"p_jobs\" \"jsonb\") OWNER TO \"postgres\"","CREATE OR REPLACE FUNCTION \"public\".\"enforce_job_field_lock\"() RETURNS \"trigger\"
    LANGUAGE \"plpgsql\"
    AS $$
BEGIN
  IF NOW() > OLD.created_at + INTERVAL ''24 hours'' THEN
    IF NEW.service_type IS DISTINCT FROM OLD.service_type THEN
      RAISE EXCEPTION ''Service type cannot be changed after 24 hours.''
        USING ERRCODE = ''check_violation'';
    END IF;
    IF NEW.job_date IS DISTINCT FROM OLD.job_date THEN
      RAISE EXCEPTION ''Job date cannot be changed after 24 hours.''
        USING ERRCODE = ''check_violation'';
    END IF;
  END IF;
  RETURN NEW;
END;
$$","ALTER FUNCTION \"public\".\"enforce_job_field_lock\"() OWNER TO \"postgres\"","CREATE OR REPLACE FUNCTION \"public\".\"generate_profile_slug\"() RETURNS \"trigger\"
    LANGUAGE \"plpgsql\"
    AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 1;
BEGIN
  base_slug := lower(regexp_replace(NEW.full_name, ''[^a-zA-Z0-9\\s]'', '''', ''g''));
  base_slug := regexp_replace(base_slug, ''\\s+'', ''-'', ''g'');
  base_slug := trim(both ''-'' from base_slug);
  final_slug := base_slug;
  WHILE EXISTS (SELECT 1 FROM users WHERE profile_slug = final_slug AND id != NEW.id) LOOP
    final_slug := base_slug || ''-'' || counter;
    counter := counter + 1;
  END LOOP;
  NEW.profile_slug := final_slug;
  RETURN NEW;
END;
$$","ALTER FUNCTION \"public\".\"generate_profile_slug\"() OWNER TO \"postgres\"","CREATE OR REPLACE FUNCTION \"public\".\"rls_auto_enable\"() RETURNS \"event_trigger\"
    LANGUAGE \"plpgsql\" SECURITY DEFINER
    SET \"search_path\" TO ''pg_catalog''
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN (''CREATE TABLE'', ''CREATE TABLE AS'', ''SELECT INTO'')
      AND object_type IN (''table'',''partitioned table'')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN (''public'') AND cmd.schema_name NOT IN (''pg_catalog'',''information_schema'') AND cmd.schema_name NOT LIKE ''pg_toast%'' AND cmd.schema_name NOT LIKE ''pg_temp%'' THEN
      BEGIN
        EXECUTE format(''alter table if exists %s enable row level security'', cmd.object_identity);
        RAISE LOG ''rls_auto_enable: enabled RLS on %'', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG ''rls_auto_enable: failed to enable RLS on %'', cmd.object_identity;
      END;
     ELSE
        RAISE LOG ''rls_auto_enable: skip % (either system schema or not in enforced list: %.)'', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$","ALTER FUNCTION \"public\".\"rls_auto_enable\"() OWNER TO \"postgres\"","CREATE OR REPLACE FUNCTION \"public\".\"update_customer_job_stats\"() RETURNS \"trigger\"
    LANGUAGE \"plpgsql\"
    AS $$
BEGIN
  IF TG_OP = ''INSERT'' THEN
    UPDATE customers
    SET total_jobs = total_jobs + 1, last_job_at = NEW.created_at, updated_at = NOW()
    WHERE id = NEW.customer_id;
  END IF;
  RETURN NEW;
END;
$$","ALTER FUNCTION \"public\".\"update_customer_job_stats\"() OWNER TO \"postgres\"","CREATE OR REPLACE FUNCTION \"public\".\"update_job_follow_up_status\"() RETURNS \"trigger\"
    LANGUAGE \"plpgsql\"
    AS $$
BEGIN
  UPDATE jobs
  SET follow_up_sent = TRUE, follow_up_sent_at = NEW.sent_at, updated_at = NOW()
  WHERE id = NEW.job_id;
  RETURN NEW;
END;
$$","ALTER FUNCTION \"public\".\"update_job_follow_up_status\"() OWNER TO \"postgres\"","CREATE OR REPLACE FUNCTION \"public\".\"update_updated_at_column\"() RETURNS \"trigger\"
    LANGUAGE \"plpgsql\"
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$","ALTER FUNCTION \"public\".\"update_updated_at_column\"() OWNER TO \"postgres\"","SET default_tablespace = ''''","SET default_table_access_method = \"heap\"","CREATE TABLE IF NOT EXISTS \"public\".\"app_events\" (
    \"id\" \"uuid\" DEFAULT \"gen_random_uuid\"() NOT NULL,
    \"user_id\" \"uuid\",
    \"event_name\" \"text\" NOT NULL,
    \"properties\" \"jsonb\" DEFAULT ''{}''::\"jsonb\",
    \"created_at\" timestamp with time zone DEFAULT \"now\"()
)","ALTER TABLE \"public\".\"app_events\" OWNER TO \"postgres\"","CREATE TABLE IF NOT EXISTS \"public\".\"customers\" (
    \"id\" \"uuid\" DEFAULT \"extensions\".\"uuid_generate_v4\"() NOT NULL,
    \"user_id\" \"uuid\" NOT NULL,
    \"full_name\" character varying(100) NOT NULL,
    \"phone_number\" \"public\".\"citext\" NOT NULL,
    \"location\" character varying(255),
    \"notes\" character varying(1000),
    \"total_jobs\" integer DEFAULT 0 NOT NULL,
    \"last_job_at\" timestamp with time zone,
    \"deleted_at\" timestamp with time zone,
    \"created_at\" timestamp with time zone DEFAULT \"now\"() NOT NULL,
    \"updated_at\" timestamp with time zone DEFAULT \"now\"() NOT NULL,
    CONSTRAINT \"customers_full_name_check\" CHECK ((\"char_length\"((\"full_name\")::\"text\") >= 2)),
    CONSTRAINT \"customers_total_jobs_check\" CHECK ((\"total_jobs\" >= 0))
)","ALTER TABLE \"public\".\"customers\" OWNER TO \"postgres\"","CREATE TABLE IF NOT EXISTS \"public\".\"follow_ups\" (
    \"id\" \"uuid\" DEFAULT \"extensions\".\"uuid_generate_v4\"() NOT NULL,
    \"job_id\" \"uuid\" NOT NULL,
    \"user_id\" \"uuid\" NOT NULL,
    \"customer_id\" \"uuid\" NOT NULL,
    \"message_text\" character varying(1000) NOT NULL,
    \"sent_at\" timestamp with time zone DEFAULT \"now\"() NOT NULL,
    \"delivery_confirmed\" boolean DEFAULT false NOT NULL,
    \"created_at\" timestamp with time zone DEFAULT \"now\"() NOT NULL,
    CONSTRAINT \"follow_ups_message_text_check\" CHECK ((\"char_length\"((\"message_text\")::\"text\") >= 10))
)","ALTER TABLE \"public\".\"follow_ups\" OWNER TO \"postgres\"","CREATE TABLE IF NOT EXISTS \"public\".\"jobs\" (
    \"id\" \"uuid\" DEFAULT \"extensions\".\"uuid_generate_v4\"() NOT NULL,
    \"user_id\" \"uuid\" NOT NULL,
    \"customer_id\" \"uuid\" NOT NULL,
    \"service_type\" \"public\".\"service_type\" NOT NULL,
    \"job_date\" \"date\" DEFAULT CURRENT_DATE NOT NULL,
    \"location\" character varying(255),
    \"latitude\" numeric(9,6),
    \"longitude\" numeric(9,6),
    \"notes\" character varying(2000),
    \"amount_charged\" numeric(8,2),
    \"follow_up_sent\" boolean DEFAULT false NOT NULL,
    \"follow_up_sent_at\" timestamp with time zone,
    \"sync_status\" \"public\".\"sync_status\" DEFAULT ''pending''::\"public\".\"sync_status\" NOT NULL,
    \"is_archived\" boolean DEFAULT false NOT NULL,
    \"created_at\" timestamp with time zone DEFAULT \"now\"() NOT NULL,
    \"updated_at\" timestamp with time zone DEFAULT \"now\"() NOT NULL,
    CONSTRAINT \"jobs_amount_charged_check\" CHECK ((\"amount_charged\" >= (0)::numeric)),
    CONSTRAINT \"jobs_coordinates_together\" CHECK ((((\"latitude\" IS NULL) AND (\"longitude\" IS NULL)) OR ((\"latitude\" IS NOT NULL) AND (\"longitude\" IS NOT NULL)))),
    CONSTRAINT \"jobs_date_not_future\" CHECK ((\"job_date\" <= CURRENT_DATE)),
    CONSTRAINT \"jobs_latitude_check\" CHECK (((\"latitude\" >= (''-90''::integer)::numeric) AND (\"latitude\" <= (90)::numeric))),
    CONSTRAINT \"jobs_longitude_check\" CHECK (((\"longitude\" >= (''-180''::integer)::numeric) AND (\"longitude\" <= (180)::numeric)))
)","ALTER TABLE \"public\".\"jobs\" OWNER TO \"postgres\"","CREATE TABLE IF NOT EXISTS \"public\".\"knowledge_notes\" (
    \"id\" \"uuid\" DEFAULT \"extensions\".\"uuid_generate_v4\"() NOT NULL,
    \"user_id\" \"uuid\" NOT NULL,
    \"title\" character varying(200) NOT NULL,
    \"description\" \"text\" NOT NULL,
    \"tags\" \"text\"[] DEFAULT ''{}''::\"text\"[],
    \"photo_url\" character varying(500),
    \"service_type\" \"public\".\"service_type\",
    \"is_archived\" boolean DEFAULT false NOT NULL,
    \"created_at\" timestamp with time zone DEFAULT \"now\"() NOT NULL,
    \"updated_at\" timestamp with time zone DEFAULT \"now\"() NOT NULL,
    CONSTRAINT \"knowledge_notes_description_check\" CHECK ((\"char_length\"(\"description\") >= 10)),
    CONSTRAINT \"knowledge_notes_max_tags\" CHECK (((\"array_length\"(\"tags\", 1) <= 10) OR (\"tags\" = ''{}''::\"text\"[]))),
    CONSTRAINT \"knowledge_notes_title_check\" CHECK ((\"char_length\"((\"title\")::\"text\") >= 3))
)","ALTER TABLE \"public\".\"knowledge_notes\" OWNER TO \"postgres\"","CREATE TABLE IF NOT EXISTS \"public\".\"profiles\" (
    \"id\" \"uuid\" DEFAULT \"extensions\".\"uuid_generate_v4\"() NOT NULL,
    \"user_id\" \"uuid\" NOT NULL,
    \"display_name\" character varying(100) NOT NULL,
    \"bio\" character varying(300),
    \"photo_url\" character varying(500),
    \"services\" \"public\".\"service_type\"[] DEFAULT ''{}''::\"public\".\"service_type\"[] NOT NULL,
    \"whatsapp_number\" \"public\".\"citext\" NOT NULL,
    \"is_public\" boolean DEFAULT true NOT NULL,
    \"profile_url\" character varying(255) NOT NULL,
    \"created_at\" timestamp with time zone DEFAULT \"now\"() NOT NULL,
    \"updated_at\" timestamp with time zone DEFAULT \"now\"() NOT NULL,
    CONSTRAINT \"profiles_display_name_check\" CHECK ((\"char_length\"((\"display_name\")::\"text\") >= 2)),
    CONSTRAINT \"profiles_services_not_empty\" CHECK ((\"array_length\"(\"services\", 1) >= 1))
)","ALTER TABLE \"public\".\"profiles\" OWNER TO \"postgres\"","CREATE TABLE IF NOT EXISTS \"public\".\"users\" (
    \"id\" \"uuid\" DEFAULT \"extensions\".\"uuid_generate_v4\"() NOT NULL,
    \"auth_id\" \"uuid\",
    \"full_name\" character varying(100) NOT NULL,
    \"phone_number\" \"public\".\"citext\" NOT NULL,
    \"email\" \"public\".\"citext\",
    \"role\" \"public\".\"user_role\" DEFAULT ''technician''::\"public\".\"user_role\" NOT NULL,
    \"status\" \"public\".\"user_status\" DEFAULT ''pending''::\"public\".\"user_status\" NOT NULL,
    \"profile_slug\" character varying(50) NOT NULL,
    \"last_seen_at\" timestamp with time zone,
    \"created_at\" timestamp with time zone DEFAULT \"now\"() NOT NULL,
    \"updated_at\" timestamp with time zone DEFAULT \"now\"() NOT NULL,
    CONSTRAINT \"users_full_name_check\" CHECK ((\"char_length\"((\"full_name\")::\"text\") >= 2))
)","ALTER TABLE \"public\".\"users\" OWNER TO \"postgres\"","ALTER TABLE ONLY \"public\".\"app_events\"
    ADD CONSTRAINT \"app_events_pkey\" PRIMARY KEY (\"id\")","ALTER TABLE ONLY \"public\".\"customers\"
    ADD CONSTRAINT \"customers_phone_unique_per_user\" UNIQUE (\"user_id\", \"phone_number\")","ALTER TABLE ONLY \"public\".\"customers\"
    ADD CONSTRAINT \"customers_pkey\" PRIMARY KEY (\"id\")","ALTER TABLE ONLY \"public\".\"follow_ups\"
    ADD CONSTRAINT \"follow_ups_job_id_key\" UNIQUE (\"job_id\")","ALTER TABLE ONLY \"public\".\"follow_ups\"
    ADD CONSTRAINT \"follow_ups_pkey\" PRIMARY KEY (\"id\")","ALTER TABLE ONLY \"public\".\"jobs\"
    ADD CONSTRAINT \"jobs_pkey\" PRIMARY KEY (\"id\")","ALTER TABLE ONLY \"public\".\"knowledge_notes\"
    ADD CONSTRAINT \"knowledge_notes_pkey\" PRIMARY KEY (\"id\")","ALTER TABLE ONLY \"public\".\"profiles\"
    ADD CONSTRAINT \"profiles_pkey\" PRIMARY KEY (\"id\")","ALTER TABLE ONLY \"public\".\"profiles\"
    ADD CONSTRAINT \"profiles_profile_url_key\" UNIQUE (\"profile_url\")","ALTER TABLE ONLY \"public\".\"profiles\"
    ADD CONSTRAINT \"profiles_user_id_key\" UNIQUE (\"user_id\")","ALTER TABLE ONLY \"public\".\"users\"
    ADD CONSTRAINT \"users_auth_id_key\" UNIQUE (\"auth_id\")","ALTER TABLE ONLY \"public\".\"users\"
    ADD CONSTRAINT \"users_email_key\" UNIQUE (\"email\")","ALTER TABLE ONLY \"public\".\"users\"
    ADD CONSTRAINT \"users_phone_number_key\" UNIQUE (\"phone_number\")","ALTER TABLE ONLY \"public\".\"users\"
    ADD CONSTRAINT \"users_pkey\" PRIMARY KEY (\"id\")","ALTER TABLE ONLY \"public\".\"users\"
    ADD CONSTRAINT \"users_profile_slug_key\" UNIQUE (\"profile_slug\")","CREATE INDEX \"idx_customers_full_name\" ON \"public\".\"customers\" USING \"gin\" (\"to_tsvector\"(''\"english\"''::\"regconfig\", (\"full_name\")::\"text\"))","CREATE INDEX \"idx_customers_not_deleted\" ON \"public\".\"customers\" USING \"btree\" (\"user_id\") WHERE (\"deleted_at\" IS NULL)","CREATE INDEX \"idx_customers_phone\" ON \"public\".\"customers\" USING \"btree\" (\"user_id\", \"phone_number\")","CREATE INDEX \"idx_customers_user_id\" ON \"public\".\"customers\" USING \"btree\" (\"user_id\")","CREATE INDEX \"idx_follow_ups_job_id\" ON \"public\".\"follow_ups\" USING \"btree\" (\"job_id\")","CREATE INDEX \"idx_follow_ups_user_id\" ON \"public\".\"follow_ups\" USING \"btree\" (\"user_id\")","CREATE INDEX \"idx_jobs_customer_id\" ON \"public\".\"jobs\" USING \"btree\" (\"customer_id\")","CREATE INDEX \"idx_jobs_follow_up\" ON \"public\".\"jobs\" USING \"btree\" (\"user_id\", \"follow_up_sent\")","CREATE INDEX \"idx_jobs_job_date\" ON \"public\".\"jobs\" USING \"btree\" (\"user_id\", \"job_date\" DESC)","CREATE INDEX \"idx_jobs_service_type\" ON \"public\".\"jobs\" USING \"btree\" (\"user_id\", \"service_type\")","CREATE INDEX \"idx_jobs_sync_status\" ON \"public\".\"jobs\" USING \"btree\" (\"user_id\", \"sync_status\") WHERE (\"sync_status\" <> ''synced''::\"public\".\"sync_status\")","CREATE INDEX \"idx_jobs_user_id\" ON \"public\".\"jobs\" USING \"btree\" (\"user_id\")","CREATE INDEX \"idx_knowledge_notes_not_archived\" ON \"public\".\"knowledge_notes\" USING \"btree\" (\"user_id\") WHERE (\"is_archived\" = false)","CREATE INDEX \"idx_knowledge_notes_search\" ON \"public\".\"knowledge_notes\" USING \"gin\" (\"to_tsvector\"(''\"english\"''::\"regconfig\", (((\"title\")::\"text\" || '' ''::\"text\") || \"description\")))","CREATE INDEX \"idx_knowledge_notes_tags\" ON \"public\".\"knowledge_notes\" USING \"gin\" (\"tags\")","CREATE INDEX \"idx_knowledge_notes_user_id\" ON \"public\".\"knowledge_notes\" USING \"btree\" (\"user_id\")","CREATE INDEX \"idx_profiles_is_public\" ON \"public\".\"profiles\" USING \"btree\" (\"is_public\") WHERE (\"is_public\" = true)","CREATE INDEX \"idx_profiles_profile_url\" ON \"public\".\"profiles\" USING \"btree\" (\"profile_url\")","CREATE INDEX \"idx_users_phone\" ON \"public\".\"users\" USING \"btree\" (\"phone_number\")","CREATE INDEX \"idx_users_profile_slug\" ON \"public\".\"users\" USING \"btree\" (\"profile_slug\")","CREATE INDEX \"idx_users_role\" ON \"public\".\"users\" USING \"btree\" (\"role\")","CREATE OR REPLACE TRIGGER \"trigger_enforce_job_lock\" BEFORE UPDATE ON \"public\".\"jobs\" FOR EACH ROW EXECUTE FUNCTION \"public\".\"enforce_job_field_lock\"()","CREATE OR REPLACE TRIGGER \"trigger_generate_profile_slug\" BEFORE INSERT ON \"public\".\"users\" FOR EACH ROW EXECUTE FUNCTION \"public\".\"generate_profile_slug\"()","CREATE OR REPLACE TRIGGER \"trigger_update_customer_stats\" AFTER INSERT ON \"public\".\"jobs\" FOR EACH ROW EXECUTE FUNCTION \"public\".\"update_customer_job_stats\"()","CREATE OR REPLACE TRIGGER \"trigger_update_job_follow_up\" AFTER INSERT ON \"public\".\"follow_ups\" FOR EACH ROW EXECUTE FUNCTION \"public\".\"update_job_follow_up_status\"()","CREATE OR REPLACE TRIGGER \"update_customers_updated_at\" BEFORE UPDATE ON \"public\".\"customers\" FOR EACH ROW EXECUTE FUNCTION \"public\".\"update_updated_at_column\"()","CREATE OR REPLACE TRIGGER \"update_jobs_updated_at\" BEFORE UPDATE ON \"public\".\"jobs\" FOR EACH ROW EXECUTE FUNCTION \"public\".\"update_updated_at_column\"()","CREATE OR REPLACE TRIGGER \"update_knowledge_notes_updated_at\" BEFORE UPDATE ON \"public\".\"knowledge_notes\" FOR EACH ROW EXECUTE FUNCTION \"public\".\"update_updated_at_column\"()","CREATE OR REPLACE TRIGGER \"update_profiles_updated_at\" BEFORE UPDATE ON \"public\".\"profiles\" FOR EACH ROW EXECUTE FUNCTION \"public\".\"update_updated_at_column\"()","CREATE OR REPLACE TRIGGER \"update_users_updated_at\" BEFORE UPDATE ON \"public\".\"users\" FOR EACH ROW EXECUTE FUNCTION \"public\".\"update_updated_at_column\"()","ALTER TABLE ONLY \"public\".\"app_events\"
    ADD CONSTRAINT \"app_events_user_id_fkey\" FOREIGN KEY (\"user_id\") REFERENCES \"auth\".\"users\"(\"id\") ON DELETE SET NULL","ALTER TABLE ONLY \"public\".\"customers\"
    ADD CONSTRAINT \"customers_user_id_fkey\" FOREIGN KEY (\"user_id\") REFERENCES \"auth\".\"users\"(\"id\") ON DELETE CASCADE","ALTER TABLE ONLY \"public\".\"follow_ups\"
    ADD CONSTRAINT \"follow_ups_customer_id_fkey\" FOREIGN KEY (\"customer_id\") REFERENCES \"public\".\"customers\"(\"id\")","ALTER TABLE ONLY \"public\".\"follow_ups\"
    ADD CONSTRAINT \"follow_ups_job_id_fkey\" FOREIGN KEY (\"job_id\") REFERENCES \"public\".\"jobs\"(\"id\") ON DELETE CASCADE","ALTER TABLE ONLY \"public\".\"follow_ups\"
    ADD CONSTRAINT \"follow_ups_user_id_fkey\" FOREIGN KEY (\"user_id\") REFERENCES \"public\".\"users\"(\"id\") ON DELETE CASCADE","ALTER TABLE ONLY \"public\".\"jobs\"
    ADD CONSTRAINT \"jobs_customer_id_fkey\" FOREIGN KEY (\"customer_id\") REFERENCES \"public\".\"customers\"(\"id\")","ALTER TABLE ONLY \"public\".\"jobs\"
    ADD CONSTRAINT \"jobs_user_id_fkey\" FOREIGN KEY (\"user_id\") REFERENCES \"public\".\"users\"(\"id\") ON DELETE CASCADE","ALTER TABLE ONLY \"public\".\"knowledge_notes\"
    ADD CONSTRAINT \"knowledge_notes_user_id_fkey\" FOREIGN KEY (\"user_id\") REFERENCES \"auth\".\"users\"(\"id\") ON DELETE CASCADE","ALTER TABLE ONLY \"public\".\"profiles\"
    ADD CONSTRAINT \"profiles_user_id_fkey\" FOREIGN KEY (\"user_id\") REFERENCES \"auth\".\"users\"(\"id\") ON DELETE CASCADE","ALTER TABLE ONLY \"public\".\"users\"
    ADD CONSTRAINT \"users_auth_id_fkey\" FOREIGN KEY (\"auth_id\") REFERENCES \"auth\".\"users\"(\"id\") ON DELETE CASCADE","ALTER TABLE \"public\".\"app_events\" ENABLE ROW LEVEL SECURITY","CREATE POLICY \"app_events_insert_own\" ON \"public\".\"app_events\" FOR INSERT TO \"authenticated\" WITH CHECK (((\"auth\".\"uid\"() = \"user_id\") OR (\"user_id\" IS NULL)))","CREATE POLICY \"app_events_select_own\" ON \"public\".\"app_events\" FOR SELECT TO \"authenticated\" USING ((\"auth\".\"uid\"() = \"user_id\"))","ALTER TABLE \"public\".\"customers\" ENABLE ROW LEVEL SECURITY","CREATE POLICY \"customers_delete_own\" ON \"public\".\"customers\" FOR DELETE USING ((\"auth\".\"uid\"() = \"user_id\"))","CREATE POLICY \"customers_insert_own\" ON \"public\".\"customers\" FOR INSERT WITH CHECK ((\"auth\".\"uid\"() = \"user_id\"))","CREATE POLICY \"customers_select_own\" ON \"public\".\"customers\" FOR SELECT USING (((\"auth\".\"uid\"() = \"user_id\") AND (\"deleted_at\" IS NULL)))","CREATE POLICY \"customers_update_own\" ON \"public\".\"customers\" FOR UPDATE USING ((\"auth\".\"uid\"() = \"user_id\"))","ALTER TABLE \"public\".\"follow_ups\" ENABLE ROW LEVEL SECURITY","CREATE POLICY \"follow_ups_insert_own\" ON \"public\".\"follow_ups\" FOR INSERT WITH CHECK ((\"auth\".\"uid\"() = \"user_id\"))","CREATE POLICY \"follow_ups_select_own\" ON \"public\".\"follow_ups\" FOR SELECT USING ((\"auth\".\"uid\"() = \"user_id\"))","CREATE POLICY \"followups_insert_own\" ON \"public\".\"follow_ups\" FOR INSERT WITH CHECK ((\"user_id\" IN ( SELECT \"users\".\"id\"
   FROM \"public\".\"users\"
  WHERE (\"users\".\"auth_id\" = \"auth\".\"uid\"()))))","CREATE POLICY \"followups_select_own\" ON \"public\".\"follow_ups\" FOR SELECT USING ((\"user_id\" IN ( SELECT \"users\".\"id\"
   FROM \"public\".\"users\"
  WHERE (\"users\".\"auth_id\" = \"auth\".\"uid\"()))))","ALTER TABLE \"public\".\"jobs\" ENABLE ROW LEVEL SECURITY","CREATE POLICY \"jobs_insert_own\" ON \"public\".\"jobs\" FOR INSERT WITH CHECK ((\"user_id\" IN ( SELECT \"users\".\"id\"
   FROM \"public\".\"users\"
  WHERE (\"users\".\"auth_id\" = \"auth\".\"uid\"()))))","CREATE POLICY \"jobs_select_own\" ON \"public\".\"jobs\" FOR SELECT USING ((\"user_id\" IN ( SELECT \"users\".\"id\"
   FROM \"public\".\"users\"
  WHERE (\"users\".\"auth_id\" = \"auth\".\"uid\"()))))","CREATE POLICY \"jobs_update_own\" ON \"public\".\"jobs\" FOR UPDATE USING ((\"user_id\" IN ( SELECT \"users\".\"id\"
   FROM \"public\".\"users\"
  WHERE (\"users\".\"auth_id\" = \"auth\".\"uid\"()))))","ALTER TABLE \"public\".\"knowledge_notes\" ENABLE ROW LEVEL SECURITY","CREATE POLICY \"notes_delete_own\" ON \"public\".\"knowledge_notes\" FOR DELETE USING ((\"auth\".\"uid\"() = \"user_id\"))","CREATE POLICY \"notes_insert_own\" ON \"public\".\"knowledge_notes\" FOR INSERT WITH CHECK ((\"auth\".\"uid\"() = \"user_id\"))","CREATE POLICY \"notes_select_own\" ON \"public\".\"knowledge_notes\" FOR SELECT USING ((\"auth\".\"uid\"() = \"user_id\"))","CREATE POLICY \"notes_update_own\" ON \"public\".\"knowledge_notes\" FOR UPDATE USING ((\"auth\".\"uid\"() = \"user_id\"))","ALTER TABLE \"public\".\"profiles\" ENABLE ROW LEVEL SECURITY","CREATE POLICY \"profiles_insert_own\" ON \"public\".\"profiles\" FOR INSERT WITH CHECK ((\"auth\".\"uid\"() = \"user_id\"))","CREATE POLICY \"profiles_public_read\" ON \"public\".\"profiles\" FOR SELECT USING ((\"is_public\" = true))","CREATE POLICY \"profiles_select_own\" ON \"public\".\"profiles\" FOR SELECT USING ((\"auth\".\"uid\"() = \"user_id\"))","CREATE POLICY \"profiles_update_own\" ON \"public\".\"profiles\" FOR UPDATE USING ((\"auth\".\"uid\"() = \"user_id\"))","ALTER TABLE \"public\".\"users\" ENABLE ROW LEVEL SECURITY","CREATE POLICY \"users_founding_read_all\" ON \"public\".\"users\" FOR SELECT USING (((\"auth\".\"jwt\"() ->> ''role''::\"text\") = ANY (ARRAY[''founding_technician''::\"text\", ''admin''::\"text\"])))","CREATE POLICY \"users_insert_own\" ON \"public\".\"users\" FOR INSERT WITH CHECK ((\"auth\".\"uid\"() = \"auth_id\"))","CREATE POLICY \"users_select_own\" ON \"public\".\"users\" FOR SELECT USING ((\"auth\".\"uid\"() = \"auth_id\"))","CREATE POLICY \"users_update_own\" ON \"public\".\"users\" FOR UPDATE USING ((\"auth\".\"uid\"() = \"auth_id\"))","ALTER PUBLICATION \"supabase_realtime\" OWNER TO \"postgres\"","GRANT USAGE ON SCHEMA \"public\" TO \"postgres\"","GRANT USAGE ON SCHEMA \"public\" TO \"anon\"","GRANT USAGE ON SCHEMA \"public\" TO \"authenticated\"","GRANT USAGE ON SCHEMA \"public\" TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citextin\"(\"cstring\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citextin\"(\"cstring\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citextin\"(\"cstring\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citextin\"(\"cstring\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citextout\"(\"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citextout\"(\"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citextout\"(\"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citextout\"(\"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citextrecv\"(\"internal\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citextrecv\"(\"internal\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citextrecv\"(\"internal\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citextrecv\"(\"internal\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citextsend\"(\"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citextsend\"(\"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citextsend\"(\"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citextsend\"(\"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext\"(boolean) TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext\"(boolean) TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext\"(boolean) TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext\"(boolean) TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext\"(character) TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext\"(character) TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext\"(character) TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext\"(character) TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext\"(\"inet\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext\"(\"inet\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext\"(\"inet\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext\"(\"inet\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"batch_sync_customers\"(\"p_user_id\" \"uuid\", \"p_customers\" \"jsonb\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"batch_sync_customers\"(\"p_user_id\" \"uuid\", \"p_customers\" \"jsonb\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"batch_sync_customers\"(\"p_user_id\" \"uuid\", \"p_customers\" \"jsonb\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"batch_sync_jobs\"(\"p_user_id\" \"uuid\", \"p_jobs\" \"jsonb\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"batch_sync_jobs\"(\"p_user_id\" \"uuid\", \"p_jobs\" \"jsonb\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"batch_sync_jobs\"(\"p_user_id\" \"uuid\", \"p_jobs\" \"jsonb\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_cmp\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_cmp\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_cmp\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_cmp\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_eq\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_eq\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_eq\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_eq\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_ge\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_ge\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_ge\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_ge\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_gt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_gt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_gt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_gt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_hash\"(\"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_hash\"(\"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_hash\"(\"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_hash\"(\"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_hash_extended\"(\"public\".\"citext\", bigint) TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_hash_extended\"(\"public\".\"citext\", bigint) TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_hash_extended\"(\"public\".\"citext\", bigint) TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_hash_extended\"(\"public\".\"citext\", bigint) TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_larger\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_larger\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_larger\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_larger\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_le\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_le\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_le\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_le\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_lt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_lt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_lt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_lt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_ne\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_ne\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_ne\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_ne\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_cmp\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_cmp\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_cmp\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_cmp\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_ge\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_ge\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_ge\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_ge\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_gt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_gt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_gt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_gt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_le\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_le\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_le\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_le\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_lt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_lt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_lt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_pattern_lt\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"citext_smaller\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"citext_smaller\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"citext_smaller\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"citext_smaller\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"enforce_job_field_lock\"() TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"enforce_job_field_lock\"() TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"enforce_job_field_lock\"() TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"generate_profile_slug\"() TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"generate_profile_slug\"() TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"generate_profile_slug\"() TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"regexp_match\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"regexp_match\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"regexp_match\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"regexp_match\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"regexp_match\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"regexp_match\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"regexp_match\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"regexp_match\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"regexp_matches\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"regexp_matches\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"regexp_matches\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"regexp_matches\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"regexp_matches\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"regexp_matches\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"regexp_matches\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"regexp_matches\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"regexp_replace\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"regexp_replace\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"regexp_replace\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"regexp_replace\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"regexp_replace\"(\"public\".\"citext\", \"public\".\"citext\", \"text\", \"text\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"regexp_replace\"(\"public\".\"citext\", \"public\".\"citext\", \"text\", \"text\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"regexp_replace\"(\"public\".\"citext\", \"public\".\"citext\", \"text\", \"text\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"regexp_replace\"(\"public\".\"citext\", \"public\".\"citext\", \"text\", \"text\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_array\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_array\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_array\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_array\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_array\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_array\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_array\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_array\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_table\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_table\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_table\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_table\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_table\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_table\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_table\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"regexp_split_to_table\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"replace\"(\"public\".\"citext\", \"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"replace\"(\"public\".\"citext\", \"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"replace\"(\"public\".\"citext\", \"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"replace\"(\"public\".\"citext\", \"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"rls_auto_enable\"() TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"rls_auto_enable\"() TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"rls_auto_enable\"() TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"split_part\"(\"public\".\"citext\", \"public\".\"citext\", integer) TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"split_part\"(\"public\".\"citext\", \"public\".\"citext\", integer) TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"split_part\"(\"public\".\"citext\", \"public\".\"citext\", integer) TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"split_part\"(\"public\".\"citext\", \"public\".\"citext\", integer) TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"strpos\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"strpos\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"strpos\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"strpos\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"texticlike\"(\"public\".\"citext\", \"text\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"texticlike\"(\"public\".\"citext\", \"text\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"texticlike\"(\"public\".\"citext\", \"text\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"texticlike\"(\"public\".\"citext\", \"text\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"texticlike\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"texticlike\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"texticlike\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"texticlike\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"texticnlike\"(\"public\".\"citext\", \"text\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"texticnlike\"(\"public\".\"citext\", \"text\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"texticnlike\"(\"public\".\"citext\", \"text\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"texticnlike\"(\"public\".\"citext\", \"text\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"texticnlike\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"texticnlike\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"texticnlike\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"texticnlike\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"texticregexeq\"(\"public\".\"citext\", \"text\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"texticregexeq\"(\"public\".\"citext\", \"text\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"texticregexeq\"(\"public\".\"citext\", \"text\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"texticregexeq\"(\"public\".\"citext\", \"text\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"texticregexeq\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"texticregexeq\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"texticregexeq\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"texticregexeq\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"texticregexne\"(\"public\".\"citext\", \"text\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"texticregexne\"(\"public\".\"citext\", \"text\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"texticregexne\"(\"public\".\"citext\", \"text\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"texticregexne\"(\"public\".\"citext\", \"text\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"texticregexne\"(\"public\".\"citext\", \"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"texticregexne\"(\"public\".\"citext\", \"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"texticregexne\"(\"public\".\"citext\", \"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"texticregexne\"(\"public\".\"citext\", \"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"translate\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"translate\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"translate\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"translate\"(\"public\".\"citext\", \"public\".\"citext\", \"text\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"update_customer_job_stats\"() TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"update_customer_job_stats\"() TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"update_customer_job_stats\"() TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"update_job_follow_up_status\"() TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"update_job_follow_up_status\"() TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"update_job_follow_up_status\"() TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"update_updated_at_column\"() TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"update_updated_at_column\"() TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"update_updated_at_column\"() TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"max\"(\"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"max\"(\"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"max\"(\"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"max\"(\"public\".\"citext\") TO \"service_role\"","GRANT ALL ON FUNCTION \"public\".\"min\"(\"public\".\"citext\") TO \"postgres\"","GRANT ALL ON FUNCTION \"public\".\"min\"(\"public\".\"citext\") TO \"anon\"","GRANT ALL ON FUNCTION \"public\".\"min\"(\"public\".\"citext\") TO \"authenticated\"","GRANT ALL ON FUNCTION \"public\".\"min\"(\"public\".\"citext\") TO \"service_role\"","GRANT ALL ON TABLE \"public\".\"app_events\" TO \"anon\"","GRANT ALL ON TABLE \"public\".\"app_events\" TO \"authenticated\"","GRANT ALL ON TABLE \"public\".\"app_events\" TO \"service_role\"","GRANT ALL ON TABLE \"public\".\"customers\" TO \"anon\"","GRANT ALL ON TABLE \"public\".\"customers\" TO \"authenticated\"","GRANT ALL ON TABLE \"public\".\"customers\" TO \"service_role\"","GRANT ALL ON TABLE \"public\".\"follow_ups\" TO \"anon\"","GRANT ALL ON TABLE \"public\".\"follow_ups\" TO \"authenticated\"","GRANT ALL ON TABLE \"public\".\"follow_ups\" TO \"service_role\"","GRANT ALL ON TABLE \"public\".\"jobs\" TO \"anon\"","GRANT ALL ON TABLE \"public\".\"jobs\" TO \"authenticated\"","GRANT ALL ON TABLE \"public\".\"jobs\" TO \"service_role\"","GRANT ALL ON TABLE \"public\".\"knowledge_notes\" TO \"anon\"","GRANT ALL ON TABLE \"public\".\"knowledge_notes\" TO \"authenticated\"","GRANT ALL ON TABLE \"public\".\"knowledge_notes\" TO \"service_role\"","GRANT ALL ON TABLE \"public\".\"profiles\" TO \"anon\"","GRANT ALL ON TABLE \"public\".\"profiles\" TO \"authenticated\"","GRANT ALL ON TABLE \"public\".\"profiles\" TO \"service_role\"","GRANT ALL ON TABLE \"public\".\"users\" TO \"anon\"","GRANT ALL ON TABLE \"public\".\"users\" TO \"authenticated\"","GRANT ALL ON TABLE \"public\".\"users\" TO \"service_role\"","ALTER DEFAULT PRIVILEGES FOR ROLE \"postgres\" IN SCHEMA \"public\" GRANT ALL ON SEQUENCES TO \"postgres\"","ALTER DEFAULT PRIVILEGES FOR ROLE \"postgres\" IN SCHEMA \"public\" GRANT ALL ON SEQUENCES TO \"anon\"","ALTER DEFAULT PRIVILEGES FOR ROLE \"postgres\" IN SCHEMA \"public\" GRANT ALL ON SEQUENCES TO \"authenticated\"","ALTER DEFAULT PRIVILEGES FOR ROLE \"postgres\" IN SCHEMA \"public\" GRANT ALL ON SEQUENCES TO \"service_role\"","ALTER DEFAULT PRIVILEGES FOR ROLE \"postgres\" IN SCHEMA \"public\" GRANT ALL ON FUNCTIONS TO \"postgres\"","ALTER DEFAULT PRIVILEGES FOR ROLE \"postgres\" IN SCHEMA \"public\" GRANT ALL ON FUNCTIONS TO \"anon\"","ALTER DEFAULT PRIVILEGES FOR ROLE \"postgres\" IN SCHEMA \"public\" GRANT ALL ON FUNCTIONS TO \"authenticated\"","ALTER DEFAULT PRIVILEGES FOR ROLE \"postgres\" IN SCHEMA \"public\" GRANT ALL ON FUNCTIONS TO \"service_role\"","ALTER DEFAULT PRIVILEGES FOR ROLE \"postgres\" IN SCHEMA \"public\" GRANT ALL ON TABLES TO \"postgres\"","ALTER DEFAULT PRIVILEGES FOR ROLE \"postgres\" IN SCHEMA \"public\" GRANT ALL ON TABLES TO \"anon\"","ALTER DEFAULT PRIVILEGES FOR ROLE \"postgres\" IN SCHEMA \"public\" GRANT ALL ON TABLES TO \"authenticated\"","ALTER DEFAULT PRIVILEGES FOR ROLE \"postgres\" IN SCHEMA \"public\" GRANT ALL ON TABLES TO \"service_role\"","drop extension if exists \"pg_net\"","create policy \"storage_note_photos_insert\"
  on \"storage\".\"objects\"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = ''note-photos''::text) AND ((auth.uid())::text = (storage.foldername(name))[1])))","create policy \"storage_note_photos_read\"
  on \"storage\".\"objects\"
  as permissive
  for select
  to public
using ((bucket_id = ''note-photos''::text))","create policy \"storage_profile_photos_insert\"
  on \"storage\".\"objects\"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = ''profile-photos''::text) AND ((auth.uid())::text = (storage.foldername(name))[1])))","create policy \"storage_profile_photos_read\"
  on \"storage\".\"objects\"
  as permissive
  for select
  to public
using ((bucket_id = ''profile-photos''::text))","create policy \"storage_profile_photos_update\"
  on \"storage\".\"objects\"
  as permissive
  for update
  to authenticated
using (((bucket_id = ''profile-photos''::text) AND ((auth.uid())::text = (storage.foldername(name))[1])))"}', 'remote_schema');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260316013944', '{"DROP POLICY IF EXISTS follow_ups_insert_own ON public.follow_ups","DROP POLICY IF EXISTS follow_ups_select_own ON public.follow_ups"}', 'fix_follow_ups_rls');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260316153225', '{"-- Migration: dirc_003_sync_fixes
-- Fixes P2-001 (Sync Data Loss) and P2-002 (Soft Delete Sync Gap)

-- 1. Fix batch_sync_jobs to update all editable fields on conflict
CREATE OR REPLACE FUNCTION \"public\".\"batch_sync_jobs\"(\"p_user_id\" \"uuid\", \"p_jobs\" \"jsonb\") RETURNS \"jsonb\"
    LANGUAGE \"plpgsql\" SECURITY DEFINER
    AS $$
DECLARE
  job_record JSONB;
  new_job_id UUID;
  synced_jobs JSONB := ''[]''::jsonb;
  failed_jobs JSONB := ''[]''::jsonb;
BEGIN
  FOR job_record IN SELECT * FROM jsonb_array_elements(p_jobs)
  LOOP
    BEGIN
      INSERT INTO jobs (id, user_id, customer_id, service_type, job_date, location, notes, amount_charged, sync_status)
      VALUES (
        (job_record->>''id'')::UUID,
        p_user_id,
        (job_record->>''customer_id'')::UUID,
        (job_record->>''service_type'')::service_type,
        (job_record->>''job_date'')::DATE,
        job_record->>''location'',
        job_record->>''notes'',
        (job_record->>''amount_charged'')::DECIMAL,
        ''synced''
      )
      ON CONFLICT (id) DO UPDATE SET
        location = EXCLUDED.location,
        notes = EXCLUDED.notes,
        amount_charged = EXCLUDED.amount_charged,
        sync_status = EXCLUDED.sync_status,
        updated_at = NOW()
      RETURNING id INTO new_job_id;
      
      synced_jobs := synced_jobs || jsonb_build_object(''local_id'', job_record->>''id'', ''server_id'', new_job_id, ''sync_status'', ''synced'');
    EXCEPTION WHEN OTHERS THEN
      failed_jobs := failed_jobs || jsonb_build_object(''local_id'', job_record->>''id'', ''error'', SQLERRM);
    END;
  END LOOP;
  RETURN jsonb_build_object(''synced'', synced_jobs, ''failed'', failed_jobs);
END;
$$","-- 2. Fix batch_sync_customers to support deleted_at for offline soft deletes
CREATE OR REPLACE FUNCTION \"public\".\"batch_sync_customers\"(\"p_user_id\" \"uuid\", \"p_customers\" \"jsonb\") RETURNS \"jsonb\"
    LANGUAGE \"plpgsql\" SECURITY DEFINER
    AS $$
DECLARE
  customer_record JSONB;
  new_customer_id UUID;
  synced_customers JSONB := ''[]''::jsonb;
  failed_customers JSONB := ''[]''::jsonb;
BEGIN
  FOR customer_record IN SELECT * FROM jsonb_array_elements(p_customers)
  LOOP
    BEGIN
      INSERT INTO customers (id, user_id, full_name, phone_number, location, notes, deleted_at)
      VALUES (
        (customer_record->>''id'')::UUID,
        p_user_id,
        customer_record->>''full_name'',
        customer_record->>''phone_number'',
        customer_record->>''location'',
        customer_record->>''notes'',
        (customer_record->>''deleted_at'')::TIMESTAMPTZ
      )
      ON CONFLICT (user_id, phone_number) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        location = COALESCE(EXCLUDED.location, customers.location),
        notes = COALESCE(EXCLUDED.notes, customers.notes),
        deleted_at = EXCLUDED.deleted_at,
        updated_at = NOW()
      RETURNING id INTO new_customer_id;
      
      synced_customers := synced_customers || jsonb_build_object(''local_id'', customer_record->>''id'', ''server_id'', new_customer_id, ''sync_status'', ''synced'');
    EXCEPTION WHEN OTHERS THEN
      failed_customers := failed_customers || jsonb_build_object(''local_id'', customer_record->>''id'', ''error'', SQLERRM);
    END;
  END LOOP;
  RETURN jsonb_build_object(''synced'', synced_customers, ''failed'', failed_customers);
END;
$$"}', 'dirc_003_sync_fixes');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260316185330', '{"-- Migration: add_correction_requests_table
-- Task 2: Implement In-App Job Correction Request

CREATE TABLE IF NOT EXISTS \"public\".\"correction_requests\" (
    \"id\" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    \"job_id\" UUID NOT NULL REFERENCES \"public\".\"jobs\"(\"id\") ON DELETE CASCADE,
    \"user_id\" UUID NOT NULL REFERENCES \"public\".\"users\"(\"auth_id\") ON DELETE CASCADE,
    \"reason\" TEXT NOT NULL,
    \"status\" TEXT NOT NULL DEFAULT ''pending'' CHECK (status IN (''pending'', ''approved'', ''rejected'')),
    \"admin_notes\" TEXT,
    \"created_at\" TIMESTAMPTZ NOT NULL DEFAULT now(),
    \"updated_at\" TIMESTAMPTZ NOT NULL DEFAULT now()
)","-- Enable RLS
ALTER TABLE \"public\".\"correction_requests\" ENABLE ROW LEVEL SECURITY","-- Policies
CREATE POLICY \"Users can create their own correction requests\"
ON \"public\".\"correction_requests\"
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id)","CREATE POLICY \"Users can view their own correction requests\"
ON \"public\".\"correction_requests\"
FOR SELECT
TO authenticated
USING (auth.uid() = user_id)","CREATE POLICY \"Admins can view all correction requests\"
ON \"public\".\"correction_requests\"
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = ''admin''
    )
)","CREATE POLICY \"Admins can update correction requests\"
ON \"public\".\"correction_requests\"
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = ''admin''
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = ''admin''
    )
)","-- Trigger for updated_at
CREATE OR REPLACE TRIGGER \"update_correction_requests_updated_at\"
BEFORE UPDATE ON \"public\".\"correction_requests\"
FOR EACH ROW
EXECUTE FUNCTION \"public\".\"update_updated_at_column\"()"}', 'add_correction_requests_table');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('20260316200000', '{"-- Migration: admin_rls_policies
-- Purpose: Grant admins SELECT and UPDATE access to core tables for the Admin Dashboard.

-- Policies for Jobs
CREATE POLICY \"Admins can view all jobs\"
ON \"public\".\"jobs\"
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = ''admin''
    )
)","CREATE POLICY \"Admins can update all jobs\"
ON \"public\".\"jobs\"
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = ''admin''
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = ''admin''
    )
)","-- Policies for Customers
CREATE POLICY \"Admins can view all customers\"
ON \"public\".\"customers\"
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = ''admin''
    )
)","CREATE POLICY \"Admins can update all customers\"
ON \"public\".\"customers\"
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = ''admin''
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE auth_id = auth.uid() AND role = ''admin''
    )
)"}', 'admin_rls_policies');


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: supabase_admin
--



--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 61, true);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: supabase_admin
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

\unrestrict tTtRfiORzqUE2v9t9EKJOhE1t6J5nsqzISIKRV1nNEOPnBiNMlAq3qNh3n6QRy5

