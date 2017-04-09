CREATE TABLE `search_hash` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `info_hash` varchar(255) DEFAULT NULL,
  `category` varchar(255) DEFAULT NULL,
  `data_hash` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `extension` varchar(255) DEFAULT NULL,
  `classified` varchar(255) DEFAULT NULL,
  `source_ip` varchar(255) DEFAULT NULL,
  `tagged` varchar(255) DEFAULT NULL,
  `length` double DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `last_seen` varchar(255) DEFAULT NULL,
  `requests` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=153 DEFAULT CHARSET=utf8;

