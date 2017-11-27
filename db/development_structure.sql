CREATE TABLE `knowledges` (
  `id` int(11) NOT NULL auto_increment,
  `nr_of_answers` int(11) default '0',
  `nr_of_correct_answers` int(11) default '0',
  `time_for_last_correct_answer` datetime default NULL,
  `user_id` int(11) default NULL,
  `query_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `languages` (
  `id` int(11) NOT NULL auto_increment,
  `own_name` varchar(255) default NULL,
  `english_name` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=latin1;

CREATE TABLE `lessons` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `question_lang_id` int(11) NOT NULL,
  `answer_lang_id` int(11) NOT NULL,
  `is_private` tinyint(1) default '0',
  `user_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=46 DEFAULT CHARSET=latin1;

CREATE TABLE `queries` (
  `id` int(11) NOT NULL auto_increment,
  `question` varchar(255) default NULL,
  `answer` varchar(255) default NULL,
  `clue` varchar(255) default NULL,
  `lesson_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=324 DEFAULT CHARSET=latin1;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `statistics` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `language_id` int(11) default NULL,
  `wordcount` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  `hashed_password` varchar(255) default NULL,
  `salt` varchar(255) default NULL,
  `display_language` varchar(255) default 'English',
  `quiz_length` int(11) default '10',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `native_language` int(11) default '3',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

INSERT INTO schema_migrations (version) VALUES ('20090201104319');

INSERT INTO schema_migrations (version) VALUES ('20090531071810');

INSERT INTO schema_migrations (version) VALUES ('20090531071816');

INSERT INTO schema_migrations (version) VALUES ('20090531071822');

INSERT INTO schema_migrations (version) VALUES ('20090531071835');

INSERT INTO schema_migrations (version) VALUES ('20090620121216');

INSERT INTO schema_migrations (version) VALUES ('20090620122403');

INSERT INTO schema_migrations (version) VALUES ('20090620122424');

INSERT INTO schema_migrations (version) VALUES ('20090620150240');

INSERT INTO schema_migrations (version) VALUES ('20090816055248');