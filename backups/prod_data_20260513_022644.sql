--
-- PostgreSQL database dump
--

\restrict 0VEYkdWdOvd7pgo8eHjEU3PSLBewL8bQW55K7wHoevTraEqZuvzKca6NfTxCsnt

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
-- Data for Name: app_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.app_events VALUES ('59bc0fcd-795c-4146-a89a-2cb3f95b3cf3', '68c2027e-dc87-4dad-b817-8b039091e41f', 'profile_shared', '{}', '2026-03-21 17:03:43.411126+00');
INSERT INTO public.app_events VALUES ('18c2bd7f-3aae-4d78-ab19-1e6de78c0d07', '404db5ec-6407-4748-8b7b-43ec6cd244f2', 'profile_shared', '{}', '2026-03-23 16:07:48.615745+00');


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.customers VALUES ('45468344-0fe8-4889-8549-4174a01ebfb4', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Dodge ram', '+233244254396', '', NULL, 2, '2026-05-05 20:56:04.582856+00', NULL, '2026-05-05 20:47:19.993307+00', '2026-05-05 20:56:04.582856+00');
INSERT INTO public.customers VALUES ('8710c88a-8076-45f6-b9bb-5f162cd5547a', '68c2027e-dc87-4dad-b817-8b039091e41f', 'kojo', '+233591003237', 'abeka', NULL, 1, '2026-03-21 17:07:58.92572+00', NULL, '2026-03-21 17:07:57.718086+00', '2026-03-21 17:07:58.92572+00');
INSERT INTO public.customers VALUES ('ceb4a972-2807-401e-81b8-3dbe4c9b84cf', '68c2027e-dc87-4dad-b817-8b039091e41f', 'door customer', '+233550890649', 'madina estate Presbyterian Church', NULL, 2, '2026-03-22 21:49:37.285975+00', NULL, '2026-03-22 21:41:06.579798+00', '2026-03-22 21:49:37.285975+00');
INSERT INTO public.customers VALUES ('b5e28b6a-7107-4f01-a8c9-aaafe60f95a5', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Hyundai sonata', '+233247345850', 'ashaman', NULL, 1, '2026-03-22 21:52:42.867506+00', NULL, '2026-03-22 21:52:39.398814+00', '2026-03-22 21:52:42.867506+00');
INSERT INTO public.customers VALUES ('f6d0d84d-19ca-4ec0-a364-b02f12ebdaa4', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', 'Delali', '+233244412931', 'East Legon', NULL, 2, '2026-03-22 22:14:06.444749+00', NULL, '2026-03-20 23:37:42.381776+00', '2026-03-22 22:14:06.444749+00');
INSERT INTO public.customers VALUES ('3f320e5e-d807-428b-a611-33e53f0b1b3f', '68c2027e-dc87-4dad-b817-8b039091e41f', 'car dealer tema', '+233244231377', 'tema', NULL, 1, '2026-03-23 14:06:31.488746+00', NULL, '2026-03-23 14:06:27.169547+00', '2026-03-23 14:06:31.488746+00');
INSERT INTO public.customers VALUES ('12ac3f46-17ce-4a9d-8df4-bdbf1ef299f6', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', 'DANIEL', '+233244573211', 'Mystro Empire Villa', NULL, 1, '2026-03-23 22:13:59.864742+00', NULL, '2026-03-23 22:13:57.176463+00', '2026-03-23 22:13:59.864742+00');
INSERT INTO public.customers VALUES ('5ca74fc9-1c66-489f-a1d8-3b9870f46f85', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', 'MR Cymone', '+233243118151', 'Korlebu Hospital', NULL, 1, '2026-03-26 22:31:28.963974+00', NULL, '2026-03-26 22:31:27.765193+00', '2026-03-26 22:31:28.963974+00');
INSERT INTO public.customers VALUES ('e228642b-5d10-480f-8af0-84cbdd110766', '68c2027e-dc87-4dad-b817-8b039091e41f', 'spintex road coca-cola.', '+233248643119', 'spintex road', NULL, 1, '2026-05-11 14:01:29.613715+00', NULL, '2026-05-11 14:01:28.036574+00', '2026-05-11 14:01:29.613715+00');
INSERT INTO public.customers VALUES ('67db9e7b-57bd-4a78-8300-8db6e11e79da', '68c2027e-dc87-4dad-b817-8b039091e41f', 'DG of drink company Santa Maria', '+233592551627', 'santa maria', NULL, 3, '2026-03-27 19:25:35.380871+00', NULL, '2026-03-27 19:23:10.777134+00', '2026-03-27 19:25:35.380871+00');
INSERT INTO public.customers VALUES ('6d6d936d-beee-43b7-afc1-4b9d045a93d8', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Mr xx', '+233243158215', 'keta', NULL, 1, '2026-03-27 19:35:41.846486+00', NULL, '2026-03-27 19:35:40.731228+00', '2026-03-27 19:35:41.846486+00');
INSERT INTO public.customers VALUES ('3959e4ea-1566-4c99-8e32-e77923354360', '68c2027e-dc87-4dad-b817-8b039091e41f', 'tarkwa customer', '+233246243420', 'tarkwa', NULL, 1, '2026-03-30 11:29:30.155036+00', NULL, '2026-03-30 11:29:28.883102+00', '2026-03-30 11:29:30.155036+00');
INSERT INTO public.customers VALUES ('0b45b1ac-8968-4871-9c07-825274eed89f', '68c2027e-dc87-4dad-b817-8b039091e41f', 'arhim', '+233243871428', 'kasoa budubram', NULL, 1, '2026-03-30 11:31:32.890654+00', NULL, '2026-03-30 11:31:31.850868+00', '2026-03-30 11:31:32.890654+00');
INSERT INTO public.customers VALUES ('ac0ad37c-102a-4b13-a01b-7fd26c1be4aa', '68c2027e-dc87-4dad-b817-8b039091e41f', 'castumer', '+233244145326', 'pigfam', NULL, 1, '2026-03-31 12:42:09.706763+00', NULL, '2026-03-31 12:42:08.564159+00', '2026-03-31 12:42:09.706763+00');
INSERT INTO public.customers VALUES ('c951c63f-6eb5-4682-a639-9b328d892591', '68c2027e-dc87-4dad-b817-8b039091e41f', 'ford 150 2023 model', '+233246621856', 'tema community 12', NULL, 1, '2026-03-31 20:34:08.671751+00', NULL, '2026-03-31 20:34:06.958159+00', '2026-03-31 20:34:08.671751+00');
INSERT INTO public.customers VALUES ('420322ae-4331-4fd3-8d70-f598705f7f2a', '68c2027e-dc87-4dad-b817-8b039091e41f', 'customer inconu', '+233245639944', 'West Will more', NULL, 1, '2026-05-11 14:03:53.75929+00', NULL, '2026-05-11 14:03:52.538607+00', '2026-05-11 14:03:53.75929+00');
INSERT INTO public.customers VALUES ('c9ce5406-8ed5-46b3-8795-0d48ab2c6f10', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Ford explorer', '+233208738798', 'new town', NULL, 2, '2026-04-01 14:15:36.847197+00', NULL, '2026-04-01 14:07:43.37301+00', '2026-04-01 14:15:36.847197+00');
INSERT INTO public.customers VALUES ('95624bad-b662-4aeb-a234-e698340a82d5', '68c2027e-dc87-4dad-b817-8b039091e41f', 'old customer push to start elentra', '+233246680050', 'botiarno', NULL, 1, '2026-04-05 09:02:18.458616+00', NULL, '2026-04-05 09:02:17.327675+00', '2026-04-05 09:02:18.458616+00');
INSERT INTO public.customers VALUES ('2187f2e2-78f2-4030-8dce-091509d44f97', '68c2027e-dc87-4dad-b817-8b039091e41f', 'estate', '+233244275554', 'east legon', NULL, 1, '2026-04-09 20:01:13.963851+00', NULL, '2026-04-09 20:01:12.52272+00', '2026-04-09 20:01:13.963851+00');
INSERT INTO public.customers VALUES ('21222473-a8cd-4254-98c1-bd63559e7f29', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Salomon control board', '+233242509322', 'tema', NULL, 2, '2026-04-20 19:57:12.249547+00', NULL, '2026-04-02 16:34:36.743234+00', '2026-04-20 19:57:12.249547+00');
INSERT INTO public.customers VALUES ('4e0bcdd0-799f-4809-8da2-4ddd46dff97a', '68c2027e-dc87-4dad-b817-8b039091e41f', 'sidik', '+233244313132', 'Ghana tershary education', NULL, 1, '2026-04-26 06:45:49.850462+00', NULL, '2026-04-26 06:45:48.566593+00', '2026-04-26 06:45:49.850462+00');
INSERT INTO public.customers VALUES ('7da885e4-866d-4989-8af3-efc0ccc1e575', '68c2027e-dc87-4dad-b817-8b039091e41f', 'ras swedru', '+233205905320', 'swedru', NULL, 1, '2026-04-29 16:32:04.62385+00', NULL, '2026-04-29 16:32:03.4385+00', '2026-04-29 16:32:04.62385+00');
INSERT INTO public.customers VALUES ('d9fcee8b-1121-475b-b2d3-5e3c63b5f9a3', '68c2027e-dc87-4dad-b817-8b039091e41f', 'sengo', '+233544604103', 'nusuobri', NULL, 1, '2026-04-29 16:34:04.199365+00', NULL, '2026-04-29 16:34:03.110112+00', '2026-04-29 16:34:04.199365+00');
INSERT INTO public.customers VALUES ('f42922ce-88cb-44bf-af2c-eb5f9e9caa22', '68c2027e-dc87-4dad-b817-8b039091e41f', 'EVEN', '+233544009568', 'cantonment', NULL, 1, '2026-05-02 17:02:00.781149+00', NULL, '2026-05-02 17:01:59.635039+00', '2026-05-02 17:02:00.781149+00');
INSERT INTO public.customers VALUES ('a8e97234-857e-4972-8d22-bd80e0e56a84', '68c2027e-dc87-4dad-b817-8b039091e41f', 'tarkwa customer GMC', '+233246701209', 'tarkwa', NULL, 1, '2026-05-04 15:17:47.02588+00', NULL, '2026-05-04 15:17:45.736938+00', '2026-05-04 15:17:47.02588+00');


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users VALUES ('16f544a9-a18e-4f12-9637-69f8186a715d', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', 'Abel Dossa', '+233530823904', NULL, 'technician', 'pending', 'abel-dossa', NULL, '2026-03-20 23:19:44.402037+00', '2026-03-20 23:19:44.402037+00');
INSERT INTO public.users VALUES ('2adfb7a3-907a-4f64-a8c0-bd89acd42c24', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', 'John DODO', '+233531307502', NULL, 'technician', 'pending', 'john-dodo', NULL, '2026-03-20 23:37:54.389401+00', '2026-03-20 23:37:54.389401+00');
INSERT INTO public.users VALUES ('98333dac-79e0-402d-bbb6-7ea44ad33bc7', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Jeremiah Kojo Aguidi', '+233535891956', NULL, 'technician', 'pending', 'jeremiah-kojo-aguidi', NULL, '2026-03-21 10:54:09.178442+00', '2026-03-21 10:54:09.178442+00');
INSERT INTO public.users VALUES ('4b34f6e7-2219-4460-b068-0504b99476c1', '404db5ec-6407-4748-8b7b-43ec6cd244f2', 'Emmanuel Degbey', '+233549628060', NULL, 'technician', 'pending', 'emmanuel-degbey', NULL, '2026-03-23 16:05:23.085889+00', '2026-03-23 16:05:23.085889+00');


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.jobs VALUES ('348d9b55-d4a5-4672-b161-8d341c8da5a9', '16f544a9-a18e-4f12-9637-69f8186a715d', 'f6d0d84d-19ca-4ec0-a364-b02f12ebdaa4', 'car_lock_programming', '2026-03-20', 'East Legon', NULL, NULL, 'He rose', 450.00, false, NULL, 'synced', false, '2026-03-20 23:37:43.812969+00', '2026-03-20 23:37:43.812969+00');
INSERT INTO public.jobs VALUES ('2f8d58b4-f622-4116-b63d-7abc72362561', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '8710c88a-8076-45f6-b9bb-5f162cd5547a', 'car_lock_programming', '2026-03-20', 'abeka', NULL, NULL, 'key programming', 500.00, false, NULL, 'synced', false, '2026-03-21 17:07:58.92572+00', '2026-03-21 17:07:58.92572+00');
INSERT INTO public.jobs VALUES ('544282a7-b673-4655-adc4-93dfec3a9c47', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'ceb4a972-2807-401e-81b8-3dbe4c9b84cf', 'door_lock_installation', '2026-03-20', 'madina estate Presbyterian Church', NULL, NULL, 'smart lock system installation', 350.00, false, NULL, 'synced', false, '2026-03-22 21:41:10.874844+00', '2026-03-22 21:41:10.874844+00');
INSERT INTO public.jobs VALUES ('fd796b42-1634-48c3-8e54-fd7498ec3217', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'ceb4a972-2807-401e-81b8-3dbe4c9b84cf', 'door_lock_installation', '2026-03-20', 'madina estate Presbyterian Church', NULL, NULL, 'smart lock installation', 750.00, false, NULL, 'synced', false, '2026-03-22 21:49:37.285975+00', '2026-03-22 21:49:37.285975+00');
INSERT INTO public.jobs VALUES ('6e48e82b-889c-4b9e-b9a8-f5584bcaba13', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'b5e28b6a-7107-4f01-a8c9-aaafe60f95a5', 'car_lock_programming', '2026-03-20', 'ashaman', NULL, NULL, 'smart key programming', 800.00, false, NULL, 'synced', false, '2026-03-22 21:52:42.867506+00', '2026-03-22 21:52:42.867506+00');
INSERT INTO public.jobs VALUES ('1eacfb05-d15c-41bf-bc17-bc87472285b8', '16f544a9-a18e-4f12-9637-69f8186a715d', 'f6d0d84d-19ca-4ec0-a364-b02f12ebdaa4', 'car_lock_programming', '2026-03-22', 'East Legon', NULL, NULL, '', 240.00, false, NULL, 'synced', false, '2026-03-22 22:14:06.444749+00', '2026-03-22 22:14:06.444749+00');
INSERT INTO public.jobs VALUES ('a33152d3-929e-4b80-96a1-809cd3199d62', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '3f320e5e-d807-428b-a611-33e53f0b1b3f', 'car_lock_programming', '2026-03-23', 'tema', NULL, NULL, 'smart key programming for Honda crv', 900.00, false, NULL, 'synced', false, '2026-03-23 14:06:31.488746+00', '2026-03-23 14:06:31.488746+00');
INSERT INTO public.jobs VALUES ('c1804a96-a963-453c-81be-b42249cdf49a', '2adfb7a3-907a-4f64-a8c0-bd89acd42c24', '12ac3f46-17ce-4a9d-8df4-bdbf1ef299f6', 'smart_lock_installation', '2026-03-23', 'Mystro Empire Villa', NULL, NULL, 'PUSH TO START SYSTEM INSTALLATION.', 1900.00, false, NULL, 'synced', false, '2026-03-23 22:13:59.864742+00', '2026-03-26 22:23:09.902701+00');
INSERT INTO public.jobs VALUES ('0001d41f-68b6-4037-8a10-bbed3d1799d3', '2adfb7a3-907a-4f64-a8c0-bd89acd42c24', '5ca74fc9-1c66-489f-a1d8-3b9870f46f85', 'car_lock_programming', '2026-03-25', 'Korlebu Hospital', NULL, NULL, 'Honda Remote key', 600.00, false, NULL, 'synced', false, '2026-03-26 22:31:28.963974+00', '2026-03-26 22:31:28.963974+00');
INSERT INTO public.jobs VALUES ('f2144c29-c681-46d6-b24d-540a161813c4', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '67db9e7b-57bd-4a78-8300-8db6e11e79da', 'car_lock_programming', '2026-03-26', 'santa maria', NULL, NULL, 'trucking system installation  for ford explorer 2019', 650.00, false, NULL, 'synced', false, '2026-03-27 19:23:12.30555+00', '2026-03-27 19:24:37.146336+00');
INSERT INTO public.jobs VALUES ('ab815a53-b7b6-4e44-92eb-23c0a9366d79', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '67db9e7b-57bd-4a78-8300-8db6e11e79da', 'car_lock_programming', '2026-03-26', 'santa maria', NULL, NULL, 'trucking system installation', 650.00, false, NULL, 'synced', false, '2026-03-27 19:24:37.146336+00', '2026-03-27 19:24:37.146336+00');
INSERT INTO public.jobs VALUES ('8e9a5c2d-02c0-42cf-b1ed-b27876282b71', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '67db9e7b-57bd-4a78-8300-8db6e11e79da', 'car_lock_programming', '2026-03-27', 'santa maria', NULL, NULL, 'smart key programming for ford explorer 2019', 1500.00, false, NULL, 'synced', false, '2026-03-27 19:25:35.380871+00', '2026-03-27 19:25:35.380871+00');
INSERT INTO public.jobs VALUES ('9c0557c1-ffdb-4805-b186-79b110c78d5a', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '6d6d936d-beee-43b7-afc1-4b9d045a93d8', 'door_lock_repair', '2026-03-18', 'keta', NULL, NULL, 'smart lock configuration for 6 locks', 2000.00, false, NULL, 'synced', false, '2026-03-27 19:35:41.846486+00', '2026-03-27 19:35:41.846486+00');
INSERT INTO public.jobs VALUES ('b1cca269-ec7b-47bd-8fa9-9b5631bcf3f2', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '3959e4ea-1566-4c99-8e32-e77923354360', 'car_lock_programming', '2026-03-30', 'tarkwa', NULL, NULL, 'shel change and spare key programming', 600.00, false, NULL, 'synced', false, '2026-03-30 11:29:30.155036+00', '2026-03-30 11:29:30.155036+00');
INSERT INTO public.jobs VALUES ('67a90873-03f2-4dea-99f2-37a5227d0e2e', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '0b45b1ac-8968-4871-9c07-825274eed89f', 'car_lock_programming', '2026-03-30', 'kasoa budubram', NULL, NULL, 'spare key programming for Toyota voxy', 1100.00, false, NULL, 'synced', false, '2026-03-30 11:31:32.890654+00', '2026-03-30 11:31:32.890654+00');
INSERT INTO public.jobs VALUES ('0eb48fdf-5064-4833-8cd3-6a1b22c2089d', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'ac0ad37c-102a-4b13-a01b-7fd26c1be4aa', 'car_lock_programming', '2026-03-31', 'pigfam', NULL, NULL, 'key reprogram', 200.00, false, NULL, 'synced', false, '2026-03-31 12:42:09.706763+00', '2026-03-31 12:42:09.706763+00');
INSERT INTO public.jobs VALUES ('c8e1f0f6-070a-4002-9025-dcb27718ad49', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'c951c63f-6eb5-4682-a639-9b328d892591', 'car_lock_programming', '2026-03-31', 'tema community 12', NULL, NULL, 'key programming for ford 150 2023 model', 800.00, false, NULL, 'synced', false, '2026-03-31 20:34:08.671751+00', '2026-03-31 20:34:08.671751+00');
INSERT INTO public.jobs VALUES ('a8c419a1-4fad-44ed-8b3c-3cbf8681f448', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'c9ce5406-8ed5-46b3-8795-0d48ab2c6f10', 'car_lock_programming', '2026-03-18', 'new town', NULL, NULL, 'push to start system installation', 900.00, false, NULL, 'synced', false, '2026-04-01 14:07:44.573846+00', '2026-04-01 14:07:44.573846+00');
INSERT INTO public.jobs VALUES ('965f9576-684f-455f-8c47-2baedcd175b4', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'c9ce5406-8ed5-46b3-8795-0d48ab2c6f10', 'car_lock_programming', '2026-04-01', 'new town', NULL, NULL, 'spare key programming push to start', 600.00, false, NULL, 'synced', false, '2026-04-01 14:15:36.847197+00', '2026-04-01 14:15:36.847197+00');
INSERT INTO public.jobs VALUES ('78bc8c83-b686-423b-8c01-bc08483d3435', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '21222473-a8cd-4254-98c1-bd63559e7f29', 'car_lock_programming', '2026-04-02', 'tema', NULL, NULL, 'electrical system checking', 600.00, false, NULL, 'synced', false, '2026-04-02 16:34:38.091852+00', '2026-04-02 16:34:38.091852+00');
INSERT INTO public.jobs VALUES ('2f313a75-c0f3-41b8-a433-135c4e4f01c3', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '95624bad-b662-4aeb-a234-e698340a82d5', 'car_lock_programming', '2026-04-03', 'botiarno', NULL, NULL, 'push to start system change', 600.00, false, NULL, 'synced', false, '2026-04-05 09:02:18.458616+00', '2026-04-05 09:02:18.458616+00');
INSERT INTO public.jobs VALUES ('a5f3efd9-31ea-43c0-a174-57e773721a23', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '2187f2e2-78f2-4030-8dce-091509d44f97', 'door_lock_installation', '2026-04-09', 'east legon', NULL, NULL, 'smart lock installation', 600.00, false, NULL, 'synced', false, '2026-04-09 20:01:13.963851+00', '2026-04-09 20:01:13.963851+00');
INSERT INTO public.jobs VALUES ('b199e76d-5331-42a8-a3df-627799962fcd', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '21222473-a8cd-4254-98c1-bd63559e7f29', 'car_lock_programming', '2026-04-14', 'hongkong', NULL, NULL, 'control board and cluster programming', 1800.00, false, NULL, 'synced', false, '2026-04-20 19:57:12.249547+00', '2026-04-20 19:57:12.249547+00');
INSERT INTO public.jobs VALUES ('b4d072e1-75cc-490f-a078-f45a627b4f89', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '4e0bcdd0-799f-4809-8da2-4ddd46dff97a', 'door_lock_installation', '2026-04-16', 'Ghana tershary education', NULL, NULL, '12 Smart lock installation', 4000.00, false, NULL, 'synced', false, '2026-04-26 06:45:49.850462+00', '2026-04-26 06:45:49.850462+00');
INSERT INTO public.jobs VALUES ('7c9ddbb8-400f-4ba1-98b6-88ebde5c9514', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '7da885e4-866d-4989-8af3-efc0ccc1e575', 'car_lock_programming', '2026-04-28', 'swedru', NULL, NULL, 'Smart key programming', 2000.00, false, NULL, 'synced', false, '2026-04-29 16:32:04.62385+00', '2026-04-29 16:32:04.62385+00');
INSERT INTO public.jobs VALUES ('d15d9e64-0bbe-47b2-9ef0-91f6f2c68dd6', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'd9fcee8b-1121-475b-b2d3-5e3c63b5f9a3', 'door_lock_installation', '2026-04-27', 'nusuobri', NULL, NULL, 'camera installation', 300.00, false, NULL, 'synced', false, '2026-04-29 16:34:04.199365+00', '2026-04-29 16:34:04.199365+00');
INSERT INTO public.jobs VALUES ('268c2133-b1e3-4314-839c-fade29163a1e', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'f42922ce-88cb-44bf-af2c-eb5f9e9caa22', 'door_lock_installation', '2026-05-02', 'cantonment', NULL, NULL, 'lock installation and gateway installation. 800 for one', 2150.00, false, NULL, 'synced', false, '2026-05-02 17:02:00.781149+00', '2026-05-02 17:02:00.781149+00');
INSERT INTO public.jobs VALUES ('eff125f2-00c7-4c21-965d-899d3dfb5c6b', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'a8e97234-857e-4972-8d22-bd80e0e56a84', 'car_lock_programming', '2026-05-04', 'tarkwa', NULL, NULL, 'spare key programming for GMC terrain 2019', 1100.00, false, NULL, 'synced', false, '2026-05-04 15:17:47.02588+00', '2026-05-04 15:17:47.02588+00');
INSERT INTO public.jobs VALUES ('0e157b26-018d-4831-b3dd-034bfee7c3ae', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '45468344-0fe8-4889-8549-4174a01ebfb4', 'car_lock_programming', '2026-05-05', '', NULL, NULL, '', NULL, false, NULL, 'synced', true, '2026-05-05 20:47:21.331751+00', '2026-05-05 20:47:53.973325+00');
INSERT INTO public.jobs VALUES ('c336a5d1-74fc-41f1-a3fd-31ec90713c22', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '45468344-0fe8-4889-8549-4174a01ebfb4', 'car_lock_programming', '2026-05-05', 'ablekuma', NULL, NULL, 'Key programming', 400.00, false, NULL, 'synced', false, '2026-05-05 20:56:04.582856+00', '2026-05-05 20:56:04.582856+00');
INSERT INTO public.jobs VALUES ('40b02ff0-b75b-4575-9ddc-6e78378e8c34', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', 'e228642b-5d10-480f-8af0-84cbdd110766', 'car_lock_programming', '2026-05-11', 'spintex road', NULL, NULL, 'key programin ( spare key)', 500.00, false, NULL, 'synced', false, '2026-05-11 14:01:29.613715+00', '2026-05-11 14:01:29.613715+00');
INSERT INTO public.jobs VALUES ('1994a958-26ad-4589-b7bb-caed0e7c6b84', '98333dac-79e0-402d-bbb6-7ea44ad33bc7', '420322ae-4331-4fd3-8d70-f598705f7f2a', 'door_lock_repair', '2026-05-10', 'West Will more', NULL, NULL, 'door open for Kia optima', 100.00, false, NULL, 'synced', false, '2026-05-11 14:03:53.75929+00', '2026-05-11 14:03:53.75929+00');


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

INSERT INTO public.profiles VALUES ('dd9baa7f-7c54-4711-a259-00c7215951e3', 'f897b65b-33e4-4cea-b702-d6d4cb2b8cd1', 'John DODO', '', '', '{car_lock_programming,door_lock_repair}', '+233531307502', true, 'john-dodo', '2026-03-20 23:37:54.654978+00', '2026-03-20 23:37:54.654978+00');
INSERT INTO public.profiles VALUES ('7a1fcd30-10fe-44bf-bc6d-c28945b4f0b7', '273649c3-15bc-4026-b9fb-a7f44aa0ec16', 'Abel Dossa', '', 'https://ifzpdizxitlvjbmzozew.supabase.co/storage/v1/object/public/profile-photos/273649c3-15bc-4026-b9fb-a7f44aa0ec16/profile.png?t=1774049926378', '{car_lock_programming,door_lock_installation,door_lock_repair,smart_lock_installation}', '0530823904', true, 'abel-dossa', '2026-03-20 23:19:44.818114+00', '2026-03-20 23:38:52.778667+00');
INSERT INTO public.profiles VALUES ('38c80bb5-86d9-4bcf-8868-dc9b0d19520d', '68c2027e-dc87-4dad-b817-8b039091e41f', 'Jeremiah Kojo Aguidi', 'key programin 
alarm installation 
trucking installation 
smart lock 🔐 installation 
push to start system installation 
.......etc', 'https://ifzpdizxitlvjbmzozew.supabase.co/storage/v1/object/public/profile-photos/68c2027e-dc87-4dad-b817-8b039091e41f/profile.jpg?t=1774216669811', '{car_lock_programming,door_lock_installation,door_lock_repair,smart_lock_installation}', '0535891956', true, 'jeremiah-kojo-aguidi', '2026-03-21 10:54:09.645672+00', '2026-03-22 21:58:08.983318+00');
INSERT INTO public.profiles VALUES ('6a3c7016-0739-4c22-ad19-840c92b66241', '404db5ec-6407-4748-8b7b-43ec6cd244f2', 'Emmanuel Degbey', '', 'https://ifzpdizxitlvjbmzozew.supabase.co/storage/v1/object/public/profile-photos/404db5ec-6407-4748-8b7b-43ec6cd244f2/profile.jpg?t=1774282104492', '{car_lock_programming,smart_lock_installation}', '0549628060', true, 'emmanuel-degbey', '2026-03-23 16:05:23.526472+00', '2026-03-23 16:08:51.282674+00');


--
-- PostgreSQL database dump complete
--

\unrestrict 0VEYkdWdOvd7pgo8eHjEU3PSLBewL8bQW55K7wHoevTraEqZuvzKca6NfTxCsnt

