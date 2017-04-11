# 参考
    英文
    http://www.bittorrent.org/beps/bep_0005.html
    中文:
    http://www.cnblogs.com/bymax/p/4971116.html
    http://www.cnblogs.com/bymax/p/4973639.html

# 介绍
```
BEP:	5
Title:	DHT Protocol
Version:	023256c7581a4bed356e47caf8632be2834211bd
Last-Modified:	Thu Jan 12 12:29:12 2017 -0800
Author:	Andrew Loewenstern <drue@bittorrent.com>, Arvid Norberg <arvid@bittorrent.com>
Status:	Accepted
Type:	Standards Track
Created:	31-Jan-2008
Post-History:	22-March-2013: Add "implied_port" to announce_peer message, to improve NAT support
```


> BitTorrent uses a "distributed sloppy hash table" (DHT) for storing peer contact information for "trackerless" torrents. In effect, each peer becomes a tracker. The protocol is based on Kademila [1] and is implemented over UDP

> > 在dht协议中，bt客户端使用“distributed sloppy hash table”（分布式的hash表）来存储没有tracker地址的种子文件所对应的peer节点的信息，在这种情况下，每一个peer节点变成了一个tracker服务器，dht协议是在udp通信协议的基础上

>  note the terminology used in this document to avoid confusion. A "peer" is a client/server listening on a TCP port that implements the BitTorrent protocol. A "node" is a client/server listening on a UDP port implementing the distributed hash table protocol. The DHT is composed of nodes and stores the location of peers. BitTorrent clients include a DHT node, which is used to contact other nodes in the DHT to get the location of peers to download from using the BitTorrent protocol.
> > 注意这里使用的术语，一个peer节点是一个实现了bt协议并且开启了tcp监听端口的bt客户端或者服务器。一个node节点是一个实现了dht协议并且开启了udp监听端口的bt客户端或者服务器，这两者非常容易混淆。dht由很多node节点以及这些node节点保存的peer地址信息组成，一个bt客户端包括了一个dht node节点，通过这些节点来和dht网络中的其它节点通信来获取peer节点的信息，然后再通过bt协议从peer节点下载文件。


# Overview 概述
> Each node has a globally unique identifier known as the "node ID." Node IDs are chosen at random from the same 160-bit space as BitTorrent infohashes [2]. A "distance metric" is used to compare two node IDs or a node ID and an infohash for "closeness." Nodes must maintain a routing table containing the contact information for a small number of other nodes. The routing table becomes more detailed as IDs get closer to the node's own ID. Nodes know about many other nodes in the DHT that have IDs that are "close" to their own but have only a handful of contacts with IDs that are very far away from their own.
> > dht网络中每一个node节点有一个全局的唯一标识，叫node ID（节点id），节点id是随机从torrent种子文件中的160位的infohashes中随机抽取的。distance metric（距离度量）用来比较两个节点id或者节点id和infohash之间的距离。所有的节点（注意后面所有提到的node节点都简称节点，peer节点不作简写）必须保存一个routing table（路由表）保存它和dht网络中一小部分节点交流的信息。离节点id越近的其它节点id的信息越详细。所有的节点必须知道很多离它们很近的其它节点，离它们很远的节点只需要有足够的握手信息就行了。

> In Kademlia, the distance metric is XOR and the result is interpreted as an unsigned integer. distance(A,B) = |A xor B| Smaller values are closer.
> > 在Kad算法中，距离度量是对两个hash值进行XOR（异或）运算，并且把结果转换成无符号整数。distance(A,B)=|A xor B|，结果值越小，距离越近。

> When a node wants to find peers for a torrent, it uses the distance metric to compare the infohash of the torrent with the IDs of the nodes in its own routing table. It then contacts the nodes it knows about with IDs closest to the infohash and asks them for the contact information of peers currently downloading the torrent. If a contacted node knows about peers for the torrent, the peer contact information is returned with the response. Otherwise, the contacted node must respond with the contact information of the nodes in its routing table that are closest to the infohash of the torrent. The original node iteratively queries nodes that are closer to the target infohash until it cannot find any closer nodes. After the search is exhausted, the client then inserts the peer contact information for itself onto the responding nodes with IDs closest to the infohash of the torrent.
> > 当一个节点想找到一个种子文件的peer节点信息时，就使用距离算法把种子文件的infohash字段和它自己路由表中的节点id进行比较，然后和距离最近的节点进行通信，向它们发送请求获取正在下载这个种子文件的peer节点列表的信息。如果它请求的节点知道这个种子文件的peer节点列表，则把peer节点列表返回给发送请求的节点。如果不知道，它必须返回自己路由表中离infohash最近的节点列表给请求者。原始节点不断迭代的发送请求直到找到离目标infohash更近的节点。搜索结束之后，bt客户端把peer节点的信息保存在自己的路由表里面。

> The return value for a query for peers includes an opaque value known as the "token." For a node to announce that its controlling peer is downloading a torrent, it must present the token received from the same queried node in a recent query for peers. When a node attempts to "announce" a torrent, the queried node checks the token against the querying node's IP address. This is to prevent malicious hosts from signing up other hosts for torrents. Since the token is merely returned by the querying node to the same node it received the token from, the implementation is not defined. Tokens must be accepted for a reasonable amount of time after they have been distributed. The BitTorrent implementation uses the SHA1 hash of the IP address concatenated onto a secret that changes every five minutes and tokens up to ten minutes old are accepted.
> > 请求peer节点列表的返回值中包含了一个可选“token”，当一个节点声明它控制的peer节点正在下载一个种子文件时，它必须把它最近发送请求中获取的token返回向它发送请求的节点。当一个节点尝试“声明”一个种子时，被询问的节点把token和ip进行检查，这样做是为了防止冒充其它主机下载文件。因为token只是在查询节点和它获取token的节点之间发送，具体的实现没有任何限制。tokens在发布之后的一段时间之内是生效的。bittorrent客户端使用秘钥对ip进行sha1哈希，秘钥每5分钟改变一次，生成的token在10分钟内是有效的。

# Routing Table 路由表
> Every node maintains a routing table of known good nodes. The nodes in the routing table are used as starting points for queries in the DHT. Nodes from the routing table are returned in response to queries from other nodes.
> > 每一个节点都维护一个路由表保存一些已知的通信好的节点。路由表中的节点通常用来作为起始节点，当其它节点向这个节点发送请求时，路由表中的这些节点就会被返回给发送请求的几点。

> Not all nodes that we learn about are equal. Some are "good" and some are not. Many nodes using the DHT are able to send queries and receive responses, but are not able to respond to queries from other nodes. It is important that each node's routing table must contain only known good nodes. A good node is a node has responded to one of our queries within the last 15 minutes. A node is also good if it has ever responded to one of our queries and has sent us a query within the last 15 minutes. After 15 minutes of inactivity, a node becomes questionable. Nodes become bad when they fail to respond to multiple queries in a row. Nodes that we know are good are given priority over nodes with unknown status.
> > 并不是每一个已知的节点都是对等的。一些节点是活跃的（原文是“good”）的，另外一些不是。dht中的许多节点可以发送请求和接受返回，但是不会响应dht网络中其它节点的请求。每一个节点的路由表中都只保存好的节点，这一点非常重要。一个活跃的节点就是能在15分钟之内响应过请求或者在15分钟之内发送过请求的节点。15分钟之内没有活动的话，这个节点变成问题节点。当一个节点响应请求失败的话，它就变成坏的节点。活跃的节点比状态不明的节点的优先级要高（这不是显然吗？）。

> The routing table covers the entire node ID space from 0 to 2160. The routing table is subdivided into "buckets" that each cover a portion of the space. An empty table has one bucket with an ID space range of min=0, max=2160. When a node with ID "N" is inserted into the table, it is placed within the bucket that has min &lt;= N &lt; max. An empty table has only one bucket so any node must fit within it. Each bucket can only hold K nodes, currently eight, before becoming "full." When a bucket is full of known good nodes, no more nodes may be added unless our own node ID falls within the range of the bucket. In that case, the bucket is replaced by two new buckets each with half the range of the old bucket and the nodes from the old bucket are distributed among the two new ones. For a new table with only one bucket, the full bucket is always split into two new buckets covering the ranges 0..2159 and 2159..2160.
> > 路由表覆盖从0到2160完整的nodeID空间。路由表又被划分为buckets(桶)，每一个bucket包含一个子部分的nodeID空间。一个空的路由表只有一个bucket，它的ID范围从min=0到max=2160。当一个nodeID为“N”的node插入到表中时，它将被放到ID范围在min< N < max的bucket中。一个空的路由表只有一个bucket所以所有的node都将被放到这个bucket中。每一个bucket最多只能保存K个nodes，当前K=8。当一个bucket放满了好的nodes之后，将不再允许新的节点加入，除非我们自身的nodeID在这个bucket的范围内。在这样的情况下，这个bucket将被分裂为2个新的buckets，每一个新桶的范围都是原来旧桶的一半。原来旧桶中的nodes将被重新分配到这两个新的buckets中。如果是一个只有一个bucket的新表，这个包含整个范围的bucket将总被分裂为2个新的buckets，第一个的覆盖范围从0..2159，第二个的范围从2159..2160。

> When the bucket is full of good nodes, the new node is simply discarded. If any nodes in the bucket are known to have become bad, then one is replaced by the new node. If there are any questionable nodes in the bucket have not been seen in the last 15 minutes, the least recently seen node is pinged. If the pinged node responds then the next least recently seen questionable node is pinged until one fails to respond or all of the nodes in the bucket are known to be good. If a node in the bucket fails to respond to a ping, it is suggested to try once more before discarding the node and replacing it with a new good node. In this way, the table fills with stable long running nodes.
> > 当bucket装满了好的nodes，那么新的node将被丢弃。一旦bucket中的某一个node变为了坏的node，那么我们就用新的node来替换这个坏的node。如果bucket中有在15分钟内都没有活跃过的节点，我们将这样的节点视为可疑的节点，这时我们向最久没有联系的节点发送ping。如果被pinged的节点给出了回复，那么我们向下一个可疑的节点发送ping，不断这样循环下去，直到有某一个node没有给出ping的回复，或者当前bucket中的所有nodes都是好的(也就是所有nodes都不是可疑nodes，他们在过去15分钟内都有活动)。如果bucket中的某个node没有对我们的ping给出回复，我们最好再试一次(再发送一次ping，因为这个node也许仍然是活跃的，但由于网络拥塞，所以发生了丢包现象，注意DHT的包都是UDP的)，而不是立即丢弃这个node或者直接用新node来替代它。这样，我们得路由表将充满稳定的长时间在线的nodes。

> Each bucket should maintain a "last changed" property to indicate how "fresh" the contents are. When a node in a bucket is pinged and it responds, or a node is added to a bucket, or a node in a bucket is replaced with another node, the bucket's last changed property should be updated. Buckets that have not been changed in 15 minutes should be "refreshed." This is done by picking a random ID in the range of the bucket and performing a find_nodes search on it. Nodes that are able to receive queries from other nodes usually do not need to refresh buckets often. Nodes that are not able to receive queries from other nodes usually will need to refresh all buckets periodically to ensure there are good nodes in their table when the DHT is needed.
> > 每一个bucket都应该维持一个“lastchange”字段来表明bucket中的nodes有多新鲜。当一个bucket中的node被ping并给出了回复，或者一个node被加入到了bucket，或者一个node被一个新的node所替代，bucket的“lastchanged”字段都应当被更新。如果一个bucket的“lastchange”在过去的15分钟内都没有变化，那么我们将更新它。这个更新bucket操作是这样完成的：从这个bucket所覆盖的范围中随机选择一个ID，并对这个ID执行find_nodes查找操作。常常收到请求的nodes通常不需要常常更新自己的buckets，反之，不常常收到请求的nodes常常需要周期性的执行更新所有buckets的操作，这样才能保证当我们用到DHT的时候，里面有足够多的好的nodes。

> Upon inserting the first node into its routing table and when starting up thereafter, the node should attempt to find the closest nodes in the DHT to itself. It does this by issuing find_node messages to closer and closer nodes until it cannot find any closer. The routing table should be saved between invocations of the client software.
> > 在第一个node插入路由表并开始服务后，这个node应该试着查找离自身更近的node，这个查找工作是通过不断的发布find_node消息给越来越近的nodes来完成的，当不能找到更近的节点时，这个扩散工作就结束了。路由表应当被启动工作和客户端软件保存（也就是启动的时候从客户端中读取路由表信息，结束的时候客户端软件记录到文件中）。

# BitTorrent Protocol Extension bt协议扩展
> The BitTorrent protocol has been extended to exchange node UDP port numbers between peers that are introduced by a tracker. In this way, clients can get their routing tables seeded automatically through the download of regular torrents. Newly installed clients who attempt to download a trackerless torrent on the first try will not have any nodes in their routing table and will need the contacts included in the torrent file.
> > BitTorrent协议已经被扩展为可以在通过tracker得到的peer之间互相交换nodeUDP端口号(也就是告诉对方我们的DHT服务端口号)，在这样的方式下，客户端可以通过下载普通的种子文件来自动扩展DHT路由表。新安装的客户端第一次试着下载一个无tracker的种子时，它的路由表中将没有任何nodes，这是它需要在torrent文件中找到联系信息。

> Peers supporting the DHT set the last bit of the 8-byte reserved flags exchanged in the BitTorrent protocol handshake. Peer receiving a handshake indicating the remote peer supports the DHT should send a PORT message. It begins with byte 0x09 and has a two byte payload containing the UDP port of the DHT node in network byte order. Peers that receive this message should attempt to ping the node on the received port and IP address of the remote peer. If a response to the ping is recieved, the node should attempt to insert the new contact information into their routing table according to the usual rules.
> > peers如果支持DHT协议就将BitTorrent协议握手消息的保留位的第八字节的最后一位置为1。这时如果peer收到一个handshake表明对方支持DHT协议，就应该发送PORT消息。它由字节0x09开始，payload的长度是2个字节，包含了这个peer的DHT服务使用的网络字节序的UDP端口号。当peer收到这样的消息是应当向对方的IP和消息中指定的端口号的node发送ping。如果收到了ping的回复，那么应当使用上述的方法将新node的联系信息加入到路由表中。

# Torrent File Extensions Torrent文件扩展
> A trackerless torrent dictionary does not have an "announce" key. Instead, a trackerless torrent has a "nodes" key. This key should be set to the K closest nodes in the torrent generating client's routing table. Alternatively, the key could be set to a known good node such as one operated by the person generating the torrent. Please do not automatically add "router.bittorrent.com" to torrent files or automatically add this node to clients routing tables.
> > 一个无tracker的torrent文件字典不包含announce关键字，而使用一个nodes关键字来替代。这个关键字对应的内容应该设置为torrent创建者的路由表中K个最接近的nodes。可供选择的，这个关键字也可以设置为一个已知的可用节点，比如这个torrent文件的创建者。请不要自动加入router.bittorrent.com到torrent文件中或者自动加入这个node到客户端路由表中。


```
nodes = [["<host>", <port>], ["<host>", <port>], ...]
nodes = [["127.0.0.1", 6881], ["your.router.node", 4804]]
```

# KRPC Protocol KRPC协议
> The KRPC protocol is a simple RPC mechanism consisting of bencoded dictionaries sent over UDP. A single query packet is sent out and a single packet is sent in response. There is no retry. There are three message types: query, response, and error. For the DHT protocol, there are four queries: ping, find_node, get_peers, and announce_peer.
> > KRPC协议是由B编码组成的一个简单的RPC结构，他使用UDP报文发送。一个独立的请求包被发出去然后一个独立的包被回复。这个协议没有重发。它包含3种消息：请求，回复和错误。对DHT协议而言，这里有4种请求：ping，find_node,get_peers,和announce_peer。

> A KRPC message is a single dictionary with two keys common to every message and additional keys depending on the type of message. Every message has a key "t" with a string value representing a transaction ID. This transaction ID is generated by the querying node and is echoed in the response, so responses may be correlated with multiple queries to the same node. The transaction ID should be encoded as a short string of binary numbers, typically 2 characters are enough as they cover 2^16 outstanding queries. The other key contained in every KRPC message is "y" with a single character value describing the type of message. The value of the "y" key is one of "q" for query, "r" for response, or "e" for error.
> > 一个KRPC消息由一个独立的字典组成，其中有2个关键字是所有的消息都包含的，其余的附加关键字取决于消息类型。每一个消息都包含t关键字，它是一个代表了transactionID的字符串类型。transactionID由请求node产生，并且回复中要包含回显该字段，所以回复可能对应一个节点的多个请求。transactionID应当被编码为一个短的二进制字符串，比如2个字节，这样就可以对应2^16个请求。另一个每个KRPC消息都包含的关键字是y，它由一个字节组成，表明这个消息的类型。y对应的值有三种情况：q表示请求，r表示回复，e表示错误。

# Contact Encoding 联系信息编码
> Contact information for peers is encoded as a 6-byte string. Also known as "Compact IP-address/port info" the 4-byte IP address is in network byte order with the 2 byte port in network byte order concatenated onto the end.
> > Peers的联系信息被编码为6字节的字符串。又被称为"CompactIP-address/port info"，其中前4个字节是网络字节序的IP地址，后2个字节是网络字节序的端口。

> Contact information for nodes is encoded as a 26-byte string. Also known as "Compact node info" the 20-byte Node ID in network byte order has the compact IP-address/port info concatenated to the end.
> > Nodes的联系信息被编码为26字节的字符串。又被称为"Compactnode info"，其中前20字节是网络字节序的nodeID，后面6个字节是peers的"CompactIP-address/port info"。

# Queries 请求
> Queries, or KRPC message dictionaries with a "y" value of "q", contain two additional keys; "q" and "a". Key "q" has a string value containing the method name of the query. Key "a" has a dictionary value containing named arguments to the query.
> > 请求，对应于KPRC消息字典中的“y”关键字的值是“q”，它包含2个附加的关键字“q”和“a”。关键字“q”是一个字符串类型，包含了请求的方法名字。关键字“a”一个字典类型包含了请求所附加的参数。

# Responses 回复
> Responses, or KRPC message dictionaries with a "y" value of "r", contain one additional key "r". The value of "r" is a dictionary containing named return values. Response messages are sent upon successful completion of a query.
> > 回复，对应于KPRC消息字典中的“y”关键字的值是“r”，包含了一个附加的关键字r。关键字“r”是一个字典类型，包含了返回的值。发送回复消息是在正确解析了请求消息的基础上完成的。

# Errors 错误
> Errors, or KRPC message dictionaries with a "y" value of "e", contain one additional key "e". The value of "e" is a list. The first element is an integer representing the error code. The second element is a string containing the error message. Errors are sent when a query cannot be fulfilled. The following table describes the possible error codes:
> > 错误，对应于KPRC消息字典中的y关键字的值是“e”，包含一个附加的关键字e。关键字“e”是一个列表类型。第一个元素是一个数字类型，表明了错误码。第二个元素是一个字符串类型，表明了错误信息。当一个请求不能解析或出错时，错误包将被发送。下表描述了可能出现的错误码：

Code代码 | Description描述
---|---
201 | Generic Error 一般错误
202 | Server Error 服务错误
203	| Protocol Error, such as a malformed packet, invalid arguments, or bad token  协议错误,比如不规范的包，无效的参数，或者错误的token
204	| Method Unknown 未知方法


> Example Error Packets:
> > 错误包例子:

> generic error = {"t":"aa", "y":"e", "e":[201, "A Generic Error Ocurred"]}
> > 一般错误={"t":"aa", "y":"e", "e":[201,"A Generic Error Ocurred"]}

> bencoded = d1:eli201e23:A Generic Error Ocurrede1:t2:aa1:y1:ee
> > B编码=d1:eli201e23:AGenericErrorOcurrede1:t2:aa1:y1:ee

# DHT Queries - DHT请求
>  All queries have an "id" key and value containing the node ID of the querying node. All responses have an "id" key and value containing the node ID of the responding node.
> > 所有的请求都包含一个关键字id，它包含了请求节点的nodeID。所有的回复也包含关键字id，它包含了回复节点的nodeID。

## ping
> The most basic query is a ping. "q" = "ping" A ping query has a single argument, "id" the value is a 20-byte string containing the senders node ID in network byte order. The appropriate response to a ping has a single key "id" containing the node ID of the responding node.
> > 最基础的请求就是ping。这时KPRC协议中的“q”=“ping”。Ping请求包含一个参数id，它是一个20字节的字符串包含了发送者网络字节序的nodeID。对应的ping回复也包含一个参数id，包含了回复者的nodeID。

arguments 参数:  
```
{"id" : "<querying nodes id 请求节点ID>"}
```

response 响应: 
```
{"id" : "<queried nodes id 被请求节点ID>"}
```

### Example Packets 报文包例子
#### Query
```
{"t":"aa", "y":"q", "q":"ping", "a":{"id":"abcdefghij0123456789"}}
```
> bencoded
> > d1:ad2:id20:abcdefghij0123456789e1:q4:ping1:t2:aa1:y1:qe


#### Response 

```
{"t":"aa", "y":"r", "r": {"id":"mnopqrstuvwxyz123456"}}
```
> bencoded
> > d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re


## find_node
> find node is used to find the contact information for a node given its ID. "q" == "find_node" A find_node query has two arguments, "id" containing the node ID of the querying node, and "target" containing the ID of the node sought by the queryer. When a node receives a find_node query, it should respond with a key "nodes" and value of a string containing the compact node info for the target node or the K (8) closest good nodes in its own routing table.
> > Findnode被用来查找给定ID的node的联系信息。这时KPRC协议中的q=“find_node”。find_node请求包含2个参数，第一个参数是id，包含了请求node的nodeID。第二个参数是target，包含了请求者正在查找的node的nodeID。当一个node接收到了find_node的请求，他应该给出对应的回复，回复中包含2个关键字id和nodes，nodes是一个字符串类型，包含了被请求节点的路由表中最接近目标node的K(8)个最接近的nodes的联系信息。

### arguments  
```
{"id" : "<querying nodes id>", "target" : "<id of target node>"}
```
### response
```
{"id" : "<queried nodes id>", "nodes" : "<compact node info>"}
```

### Example Packets - 报文包例子
> find_node Query 

```
{"t":"aa", "y":"q", "q":"find_node", "a": {"id":"abcdefghij0123456789", "target":"mnopqrstuvwxyz123456"}}
```
> > bencoded
```
d1:ad2:id20:abcdefghij01234567896:target20:mnopqrstuvwxyz123456e1:q9:find_node1:t2:aa1:y1:qe
```
> Response 
```
{"t":"aa", "y":"r", "r": {"id":"0123456789abcdefghij", "nodes": "def456..."}}
```
> > bencoded 
```
d1:rd2:id20:0123456789abcdefghij5:nodes9:def456...e1:t2:aa1:y1:re
```

## get_peers
> Get peers associated with a torrent infohash. "q" = "get_peers" A get_peers query has two arguments, "id" containing the node ID of the querying node, and "info_hash" containing the infohash of the torrent. If the queried node has peers for the infohash, they are returned in a key "values" as a list of strings. Each string containing "compact" format peer information for a single peer. If the queried node has no peers for the infohash, a key "nodes" is returned containing the K nodes in the queried nodes routing table closest to the infohash supplied in the query. In either case a "token" key is also included in the return value. The token value is a required argument for a future announce_peer query. The token value should be a short binary string.
> > Get peers与torrent文件的info_hash有关。这时KPRC协议中的”q”=”get_peers”。get_peers请求包含2个参数。第一个参数是id，包含了请求node的nodeID。第二个参数是info_hash，它代表torrent文件的infohash。如果被请求的节点有对应info_hash的peers，他将返回一个关键字values,这是一个列表类型的字符串。每一个字符串包含了"CompactIP-address/portinfo"格式的peers信息。如果被请求的节点没有这个infohash的peers，那么他将返回关键字nodes，这个关键字包含了被请求节点的路由表中离info_hash最近的K个nodes，使用"Compactnodeinfo"格式回复。在这两种情况下，关键字token都将被返回。token关键字在今后的annouce_peer请求中必须要携带。Token是一个短的二进制字符串。


### arguments
```
{"id" : "<querying nodes id>", "info_hash" : "<20-byte infohash of target torrent>"}
```
### response
```
{"id" : "<queried nodes id>", "token" :"<opaque write token>", "values" : ["<peer 1 info string>", "<peer 2 info string>"]}
```
or
```
{"id" : "<queried nodes id>", "token" :"<opaque write token>", "nodes" : "<compact node info>"}
```

### Example Packets - 报文包例子
> get_peers Query 
```
{"t":"aa", "y":"q", "q":"get_peers", "a": {"id":"abcdefghij0123456789", "info_hash":"mnopqrstuvwxyz123456"}}
```
> > bencoded 
```
d1:ad2:id20:abcdefghij01234567899:info_hash20:mnopqrstuvwxyz123456e1:q9:get_peers1:t2:aa1:y1:qe
```
> Response with peers 
```
{"t":"aa", "y":"r", "r": {"id":"abcdefghij0123456789", "token":"aoeusnth", "values": ["axje.u", "idhtnm"]}}
```
> > bencoded 
```
d1:rd2:id20:abcdefghij01234567895:token8:aoeusnth6:valuesl6:axje.u6:idhtnmee1:t2:aa1:y1:re
```
> Response with closest nodes 
```
{"t":"aa", "y":"r", "r": {"id":"abcdefghij0123456789", "token":"aoeusnth", "nodes": "def456..."}}
```
> > bencoded 
```
d1:rd2:id20:abcdefghij01234567895:nodes9:def456...5:token8:aoeusnthe1:t2:aa1:y1:re
```

## announce_peer
> Announce that the peer, controlling the querying node, is downloading a torrent on a port. announce_peer has four arguments: "id" containing the node ID of the querying node, "info_hash" containing the infohash of the torrent, "port" containing the port as an integer, and the "token" received in response to a previous get_peers query. The queried node must verify that the token was previously sent to the same IP address as the querying node. Then the queried node should store the IP address of the querying node and the supplied port number under the infohash in its store of peer contact information.
> > 这个请求用来表明发出announce_peer请求的node，正在某个端口下载torrent文件。announce_peer包含4个参数。第一个参数是id，包含了请求node的nodeID；第二个参数是info_hash，包含了torrent文件的infohash；第三个参数是port包含了整型的端口号，表明peer在哪个端口下载；第四个参数数是token，这是在之前的get_peers请求中收到的回复中包含的。收到announce_peer请求的node必须检查这个token与之前我们回复给这个节点get_peers的token是否相同。如果相同，那么被请求的节点将记录发送announce_peer节点的IP和请求中包含的port端口号在peer联系信息中对应的infohash下。

There is an optional argument called implied_port which value is either 0 or 1. If it is present and non-zero, the port argument should be ignored and the source port of the UDP packet should be used as the peer's port instead. This is useful for peers behind a NAT that may not know their external port, and supporting uTP, they accept incoming connections on the same port as the DHT port.

### arguments
```
{"id" : "<querying nodes id>",
  "implied_port": <0 or 1>,
  "info_hash" : "<20-byte infohash of target torrent>",
  "port" : <port number>,
  "token" : "<opaque token>"}
```

### response
```
{"id" : "<queried nodes id>"}
```
### Example Packets

> announce_peers Query 
```
{"t":"aa", "y":"q", "q":"announce_peer", "a": {"id":"abcdefghij0123456789", "implied_port": 1, "info_hash":"mnopqrstuvwxyz123456", "port": 6881, "token": "aoeusnth"}}
```
> > bencoded
```
d1:ad2:id20:abcdefghij01234567899:info_hash20:mnopqrstuvwxyz1234564:porti6881e5:token8:aoeusnthe1:q13:announce_peer1:t2:aa1:y1:qe
```
> Response 
```
{"t":"aa", "y":"r", "r": {"id":"mnopqrstuvwxyz123456"}}
```
> > bencoded 
```
d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re
```

# References
    [1] Peter Maymounkov, David Mazieres, "Kademlia: A Peer-to-peer Information System Based on the XOR Metric", IPTPS 2002. http://www.cs.rice.edu/Conferences/IPTPS02/109.pdf
    [2] Use SHA1 and plenty of entropy to ensure a unique ID.
    Copyright
    This document has been placed in the public domain.
