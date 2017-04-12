CREATE TABLE `search_hash` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `info_hash` varchar(41) NOT NULL,
  `hash_type` tinyint(4) DEFAULT NULL COMMENT '0 normal\r\n1 announce',
  `category` varchar(255) DEFAULT NULL,
  `data_hash` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `extension` varchar(255) DEFAULT NULL,
  `classified` varchar(255) DEFAULT NULL COMMENT '0 normal\r\n1 announce',
  `source_ip` varchar(255) DEFAULT NULL,
  `tagged` varchar(255) DEFAULT NULL,
  `length` double DEFAULT NULL,
  `download_cost` int(11) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `last_seen` varchar(255) DEFAULT NULL,
  `requests` varchar(255) DEFAULT NULL,
  `details` varchar(4056) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `i_info_hash` (`info_hash`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=874 DEFAULT CHARSET=utf8;


CREATE TABLE `announce_hash` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hash` varchar(41) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `download` tinyint(4) DEFAULT NULL COMMENT '0  未下载\r\n1  已下载\r\n2  出错\r\n',
  `create_time` datetime DEFAULT NULL,
  `download_time` datetime DEFAULT NULL,
  `metainfo` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `i_hash` (`hash`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


insert into search_hash_bak(select * from search_hash where details is null)
delete from search_hash where details is null




