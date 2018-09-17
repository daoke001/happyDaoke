package com.iflashigame.net 
{
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.net.NetConnection;
	import flash.net.NetGroup;
	import flash.net.NetStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import game.model.Head;
	import game.model.RoleModel;
	
	/**
	 * P2P引擎类
	 * @author 闪刀浪子
	 */
	public class ChatManager extends EventDispatcher 
	{
		private static var _instance:ChatManager;
		
		private var _peerID:String;		//自己的编码
		private var _farID:String;		//与自己连接的玩家的编码
		private var _nc:NetConnection;
		private var _com1:NetGroup;			//控制通道
		private var _com2:NetGroup;			//世界通道
		private var _com3:NetGroup;			//分区通道
		
		private var _sendStream:NetStream;		//发送流
		private var _recievedStream:NetStream;		//接收流
		
		private var _publishStream:NetStream;	//用于离线校验的流
		
		
		private var _timerArr:Dictionary;		//计时验证字典
		
		private var _arr:Array = [];			//连接用户的堆栈
		private var _server:Boolean;			//何种身份服务器还是客户端
		private var _delay:int;				//p2p连接的延迟
		private var _fight:Boolean;			//是否正在战斗中
		
		private var _helloMode:Boolean = false;	//是否侦听握手协议
		private static var MAX:int = 200;		//最大显示人数
		
		private var _leitaiMode:Boolean = false;	//擂台模式下 server=false为擂主 server=true为攻擂者
		private var _gongleiClock:Timer;			//攻击的超时计时器
		private var _leizhu:Boolean = true;
		
		public function ChatManager(singletonEnforcer:SingletonEnforcer) 
		{
			
		}
		
		public static function getInstance():ChatManager
		{
			if (ChatManager._instance == null)
			{
				ChatManager._instance = new ChatManager(new SingletonEnforcer);
			}
			return ChatManager._instance;
		}
		
		public function get peerID():String
		{
			return _peerID;
		}
		
		public function get farID():String
		{
			return _farID;
		}
		
		public function set farID(val:String)
		{
			_farID = val;
			if (_farID == null)
			{
				_sendStream.close();
				initSendStream();
			}
		}
		
		//是否为服务器端——挑战方
		public function get server():Boolean
		{
			return _server;
		}
		
		public function set server(val:Boolean)
		{
			_server = val;
		}
		
		//是否为擂主
		public function get leizhu():Boolean
		{
			return _leizhu
		}
		
		public function set leizhu(val:Boolean)
		{
			_leizhu = val;
		}
		
		public function get delay():int
		{
			return _delay;
		}
		
		public function set delay(val:int)
		{
			_delay = val;
		}
		
		public function get fight():Boolean
		{
			return _fight;
		}
		
		public function set fight(val:Boolean)
		{
			_fight = val;
		}
		
		/**
		 * 连接cirrus验证服务
		 * @param	url	连接地址
		 * @param	key	开发者密钥
		 */
		public function cirrusConnect(url:String,key:String)
		{
			if (_nc==null) 
			{
				_nc = new NetConnection();
				_nc.maxPeerConnections = 1000;
				_nc.addEventListener(NetStatusEvent.NET_STATUS, cirrusConnectHandler);
			}
			_nc.connect(url,key);
			//_nc.connect("rtmfp://125.76.228.27/");
		}
		
		private function cirrusConnectHandler(evt:NetStatusEvent)
		{
			//trace(RoleModel.getInstance().roleName,"cirrusConnectHandler:",evt.info.code);
			switch(evt.info.code)
			{
				//连接Adobe服务器成功
				case "NetConnection.Connect.Success":
					_helloMode = true;
					_peerID = _nc.nearID;
					//trace("我的编码为:", _nc.nearID);
					initSendStream();
					initPublishStream();
					dispatchEvent(new P2PEvent(P2PEvent.CIRRUS_CONNECT_SUCCESS));
				break;
				
				//连接Adobe服务器失败
				case "NetConnection.Connect.Failed":
				case "NetConnection.Connect.Rejected":
					dispatchEvent(new P2PEvent(P2PEvent.CIRRUS_CONNECT_FAIL));
				break;
				
				case "NetConnection.Connect.NetworkChange":
					//dispatchEvent(new P2PEvent(P2PEvent.NET_DISCONNECTION));
				break;
				
				//连接Group失败
				case "NetGroup.Connect.Failed":
				case "NetGroup.Connect.Rejected":
					comFaild(evt.info.group);	
				break;
				
				case "NetGroup.Connect.Success":
					comSuccess(evt.info.group);
				break;
				
				//******************************************************
				//******************************************************
				case "NetStream.Connect.Success":
				//如果成功连接到对方
				//trace("_sendStream Success");
				break;
				
				case "NetStream.Connect.Rejected":
				case "NetStream.Connect.Failed":
				break;
				
				case "NetStream.Connect.Closed":
				//联机状态下，正常断开
				if (_sendStream.peerStreams.indexOf(evt.info.stream) != -1)
				{
					
				}
				else if(evt.info.stream==_recievedStream)
				{
					//异常断开
					_farID = null;
					recievedClose();
					if (_leitaiMode == true)
					{
						dispatchEvent(new P2PEvent(P2PEvent.LEITAI_ABEND_CLOSE));
					}
					else
					{
						dispatchEvent(new P2PEvent(P2PEvent.P2P_ABEND_CLOSE));
					}
				}
				else
				{
					//trace("断开的其他情况");
				}
				break;
			}
		}
		
		/**
		 * 定义发送流
		 */
		private function initSendStream()
		{
			//trace(RoleModel.getInstance().roleName,"initSendStream..");
			_sendStream = new NetStream(_nc, NetStream.DIRECT_CONNECTIONS);
			_sendStream.addEventListener(NetStatusEvent.NET_STATUS, sendStreamConnectHandler);
			_sendStream.publish("loojoy");
						//trace(RoleModel.getInstance().roleName,"sendStreamnearNonce:",_sendStream.nearNonce,"sendStreamfarNonce:",_sendStream.farNonce);

			
			var client:Object = { };
			client.onPeerConnect = function (callers:NetStream):Boolean
			{
				//擂台模式下攻擂方为server
				if (_leitaiMode == false)
				{
					if (_farID == callers.farID)
					{
						//trace("比对授权码");
						if(_server==true)
						p2pConnect(_farID,_server);
						return true;
					}
					else
					{
						return false;
					}
				}
				//擂台模式下攻擂方为server,保存Client方的pID等待连接
				//server连接Client的时候有可能，Client方已经下线了，
				//必须有一个计时器
				else
				{
					//trace("进入擂台授权程序");
					if (_leizhu == false)
					{
						//trace("我不是擂主，只能授权擂主连接");
						//擂主来连接的时候必须与攻方记录的授权pID一致
						if (_farID == callers.farID)
						{
							//trace("擂主来了，同意连接");
							return true;
						}
						else
						{
							//trace("不是擂主来了，不同意连接");
							return false;
						}
					}
					//擂主方不需要授权
					else
					{
						//trace("我是擂主，任何人都可以连接我");
						//擂主必定为Client方
						//如果擂主已经与人连接了，其他人全部拒绝
						if (_farID == null)
						{
							//trace("还没有人连接我，你可以连接");
							_farID = callers.farID;
							p2pConnect(_farID, _leizhu);
							return true;
						}
						else
						{
							//trace("我已经与人连接了，不同意连接");
							return false;
						}
					}
				}
			}
			
			_sendStream.client=client;
		}
		
		//定义校验发布流
		private function initPublishStream()
		{
			_publishStream = new NetStream(_nc, NetStream.DIRECT_CONNECTIONS);
			_publishStream.addEventListener(NetStatusEvent.NET_STATUS, publishStreamHandler);
			_publishStream.publish("online");
			
			var client:Object = { };
			client.onPeerConnect = function(callers:NetStream):Boolean
			{
				return true;
			}
			_publishStream.client = client;
		}
		
		//校验流，没啥用
		private function publishStreamHandler(evt:NetStatusEvent)
		{
			
		}
		
		private function sendStreamConnectHandler(evt:NetStatusEvent)
		{
			//trace(RoleModel.getInstance().roleName,"sendStreamConnectHandler:", evt.info.code);
			switch(evt.info.code)
			{
				default:
				//trace("没有处理事件");
			}
		}
		
		/**
		 * 连接控制流
		 * @param	str
		 */
		public function com1Connect(str:String)
		{
			if (_com1 == null)
			{
				_com1 = new NetGroup(_nc, str);
				_com1.addEventListener(NetStatusEvent.NET_STATUS, com1ConnectHandler);
			}
		}
		
		private function com1ConnectHandler(evt:NetStatusEvent)
		{
			//trace(RoleModel.getInstance().roleName, "com1ConnectHandler:", evt.info.code);
			if (evt.info.code == "NetGroup.Posting.Notify")
			{
				var head:int = evt.info.message.readInt();
				//关机通知
				if (head == Head.SERVER_DOWN)
				{
					dispatchEvent(new P2PEvent(P2PEvent.SERVER_DOWN,false,{text:evt.info.message.readUTF()}));
				}
				//统计请求
				else if (head == Head.SERVER_COUNT_REQUEST)
				{
					var sendArray:ByteArray = new ByteArray;
					sendArray.writeInt(Head.SERVER_COUNT_RESPONSE);
					sendArray.writeUTF(RoleModel.getInstance().roleID.toString());
					sendArray.writeUTF(peerID);
					sendArray.writeUTF(RoleModel.getInstance().agent);
					sendArray.writeUTF(RoleModel.getInstance().roleName);
					sendArray.writeInt(RoleModel.getInstance().level);
					sendArray.writeInt(RoleModel.getInstance().money);
					sendArray.writeInt(RoleModel.getInstance().reverence);
					sendArray.writeInt(RoleModel.getInstance().exploit);
					sendArray.writeDouble(Math.random());
					_com2.post(sendArray);
				}
				//查询请求
				else if (head == Head.SERVER_INFO_REQUEST)
				{
					var mID:String = evt.info.message.readUTF();
					var roleID:String = evt.info.message.readUTF();
					if (roleID == RoleModel.getInstance().roleID.toString())
					{
						var arr:ByteArray = new ByteArray();
						arr.writeInt(Head.SERVER_INFO_RESPONSE);
						arr.writeUTF(RoleModel.getInstance().roleID.toString());
						arr.writeUTF(peerID);
						arr.writeUTF(RoleModel.getInstance().makeGameData());
						arr.writeFloat(Math.random());
						arr.position = 0;
						_com2.post(arr);
					}
				}
				//修改玩家信息
				else if (head == Head.SERVER_ROLE_MODIFY)
				{
					var modiID:String = evt.info.message.readUTF();
					var modiPID:String = evt.info.message.readUTF();
					if (modiID == RoleModel.getInstance().roleID.toString()&&modiPID==peerID)
					{
						dispatchEvent(new P2PEvent(P2PEvent.P2P_MODIFY,false,evt.info.message.readObject()))
					}
				}
				//踢人
				else if (head == Head.SERVER_KICK)
				{
					var kickID:String = evt.info.message.readUTF();
					var kickPID:String = evt.info.message.readUTF();
					if (kickID == RoleModel.getInstance().roleID.toString()&&kickPID==peerID)
					{
						dispatchEvent(new P2PEvent(P2PEvent.P2P_KICK, false,{text:evt.info.message.readUTF()}));
					}
				}
				else
				{
					dispatchEvent(new P2PEvent(P2PEvent.P2P_MESSAGE, false,evt.info.message.readObject()));
				}
			}
		}
		
		/**
		 * 连接聊天流
		 * @param	str
		 */
		public function com2Connect(str:String)
		{
			if (_com2 == null)
			{
				_com2 = new NetGroup(_nc, str);
				_com2.addEventListener(NetStatusEvent.NET_STATUS, com2ConnectHandler);
			}
		}
		
		private function com2ConnectHandler(evt:NetStatusEvent)
		{
			//trace(RoleModel.getInstance().roleName,"com2ConnectHandler:", evt.info.code);
			if (evt.info.code == "NetGroup.Posting.Notify")
			{
				dispatchEvent(new P2PEvent(P2PEvent.WORLD_POST_NOTIFY, false, evt.info.message));
			}
		}
		
		public function com3Connect(str:String)
		{
			if (_com3 == null)
			{
				_com3 = new NetGroup(_nc, str);
				_com3.addEventListener(NetStatusEvent.NET_STATUS, com3ConnectHandler);
			}
		}
		
		private function com3ConnectHandler(evt:NetStatusEvent)
		{
			//trace(RoleModel.getInstance().roleName,"com3ConnectHandler:", evt.info.code);
			if (evt.info.code == "NetGroup.Neighbor.Connect")
			{
				//新连接进入群组的玩家只在第一个邻居连接的时候广播一次邻居问候
				if (_helloMode == true)
				{
					//把握的信息发送给邻居
					_helloMode = false;
					dispatchEvent(new P2PEvent(P2PEvent.HELLO_NEIGHBOR, false ));
				}
			}
			else if (evt.info.code == "NetGroup.Neighbor.Disconnect")
			{
				var timer:Timer = new Timer(1000, 10);
				var obj:Object = { };
				obj.pID = evt.info.peerID;
				obj.timer = timer;
				timer.start();
				//trace("开始检测", evt.info.peerID);
				timer.addEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
				var playStream:NetStream = new NetStream(_nc, evt.info.peerID);
				obj.stream = playStream;
				playStream.addEventListener(NetStatusEvent.NET_STATUS, playStreamHandler);
				playStream.play("online");
				
				if (_timerArr == null)
				{
					_timerArr = new Dictionary;
				}
				_timerArr[timer] = obj;
			}
			else if (evt.info.code == "NetGroup.Posting.Notify")
			{
				dispatchEvent(new P2PEvent(P2PEvent.AREA_POST_NOTIFY, false, evt.info.message));
			}
		}
		
		//验证下线的超时判断
		private function timerCompleteHandler(evt:TimerEvent)
		{
			evt.currentTarget.removeEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
			var timer:Timer = evt.currentTarget as Timer;
			if (_timerArr != null)
			{
				postDeleteNeighbor(_timerArr[timer].pID);
				_timerArr[timer].stream.close();
				_timerArr[timer].stream.removeEventListener(NetStatusEvent.NET_STATUS, playStreamHandler);
				
				//trace(_timerArr[timer].pID, "已经下线");
				delete _timerArr[timer];
			}
		}
		
		//接收留
		private function playStreamHandler(evt:NetStatusEvent)
		{
			if (evt.info.code == "NetStream.Play.Start")
			{
				//trace("好像没有下线");
				evt.currentTarget.close();
				evt.currentTarget.removeEventListener(NetStatusEvent.NET_STATUS, playStreamHandler);
				if(_timerArr!=null)
				for (var i in _timerArr)
				{
					if (_timerArr!=null&&_timerArr[i].stream == evt.currentTarget)
					{
						//trace("不用移除:", _timerArr[i].pID);
						_timerArr[i].timer.stop();
						_timerArr[i].timer.removeEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
						delete _timerArr[i];
						return;
					}
				}
			}
		}
		
		//通过验证通知其他人删除邻居
		private function postDeleteNeighbor(neighbor:String)
		{
				//删除自己堆栈中的信息
				removeNeighBor(neighbor);
				
				//通知其他人删除堆栈
				var bytesArray:ByteArray = new ByteArray;
				bytesArray.writeInt(Head.REMOVE_NEIGHBOR);
				bytesArray.writeUTF(neighbor);
				bytesArray.writeFloat(Math.random());
				bytesArray.position = 0;
				areaPost(bytesArray);
		}
		
		private function comFaild(com:NetGroup)
		{
			if (com == _com1)
			dispatchEvent(new P2PEvent(P2PEvent.COM1_CONNECT_FAIL));
			else if (com == _com2)
			dispatchEvent(new P2PEvent(P2PEvent.COM2_CONNECT_FAIL));
			else if (com == _com3)
			dispatchEvent(new P2PEvent(P2PEvent.COM3_CONNECT_FAIL));
		}
		
		private function comSuccess(com:NetGroup)
		{
			if (com == _com1)
			{
				dispatchEvent(new P2PEvent(P2PEvent.COM1_CONNECT_SUCCESS));
			}
			else if (com == _com2)
			{
				dispatchEvent(new P2PEvent(P2PEvent.COM2_CONNECT_SUCCESS));
			}
			else if (com == _com3)
			{
				dispatchEvent(new P2PEvent(P2PEvent.COM3_CONNECT_SUCCESS));
			}
		}
		
		//关闭所有网络连接
		public function close()
		{
			//trace("ChatManager 退出函数被调用");
			clearTimeArr();
			
			_helloMode = false;
			_arr = [];
			if (_com1 != null) 
			{
				_com1.close();
				_com1 = null;
			}
			if (_com2 != null) 
			{
				_com2.close();
				_com2 = null;
			}
			_farID = null;
			recievedClose();
			if (_nc != null)
			{
				_nc.close();
				_nc = null;
			}
			if (_gongleiClock != null)
			{
				_gongleiClock.reset();
				_gongleiClock.removeEventListener(TimerEvent.TIMER_COMPLETE, gongleiCloskCompleteHandler);
				_gongleiClock = null;
			}
			_leizhu = false;
		}
		
		//情况用于离线判断的对象
		private function clearTimeArr()
		{
			if (_timerArr != null)
			{
				for ( var i in _timerArr)
				{
					_timerArr[i].timer.stop();
					_timerArr[i].timer.removeEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
					_timerArr[i].stream.close();
					_timerArr[i].stream.removeEventListener(NetStatusEvent.NET_STATUS, playStreamHandler);
				}
				_timerArr = null;
			}
		}
		
		public function recievedClose()
		{
			_server=false
			if (_recievedStream != null)
			{
				_recievedStream.close();
				_recievedStream = null;
			}
		}
		
		/**
		 * 世界级广播
		 * @param	msg
		 */
		public function worldPost(msg:Object)
		{
			if (_com2 != null)
			{
				_com2.post(msg);
			}
		}
		
		/**
		 * 区域内广播
		 * @param	msg
		 */
		public function areaPost(msg:Object)
		{
			if (_com3 != null)
			{
				_com3.post(msg);
			}
		}
		
		public function resetNeightBor()
		{
			_arr = [];
		}
		
		//添加邻居信息到堆栈
		public function addNeighBor(neighBor:Object)
		{
			if (findNeighBor(neighBor.pID) != -1) return;
			else if (_arr.length > MAX) return;
			
			_arr.push(neighBor);
			dispatchEvent(new P2PEvent(P2PEvent.ADD_NEIGHBOR,false,neighBor));
		}
		
		//删除邻居信息
		public function removeNeighBor(pID:String)
		{
			var index:int = findNeighBor(pID);
			if (index != -1)
			{
				_arr.splice(index, 1);
				dispatchEvent(new P2PEvent(P2PEvent.REMOVE_NEIGHBOR, false, { pID:pID } ));
			}
		}
		
		//查找邻居索引
		private function findNeighBor(pID):int
		{
			var length:int = _arr.length;
			for (var i:int = 0; i < length; i++)
			{
				var obj:Object = _arr[i];
				if (obj.pID == pID)
				return i;
			}
			return -1;
		}
		
		//状态改变
		public function changeStatus(obj:Object)
		{
			var index:int = findNeighBor(obj.pID);
			if (index != -1)
			{
				_arr[index].status = obj.status;
				dispatchEvent(new P2PEvent(P2PEvent.CHANGE_STATUS, false, obj));
			}
		}
		
		//返回所有邻居的堆栈
		public function get neighBors():Array
		{
			return _arr;
		}
		
		/**
		 * 指定用什么身份进行连接
		 * @param	pID
		 * @param	server "true"  挑战方  "false"应战方
		 */
		public function p2pConnect(pID:String,server:Boolean,replayTime:int=-1)
		{
			//trace("向", pID, "发起p2p连接");
			if (_leitaiMode == false)
			{
				_server = server;
				if (server == false)
				{
					_farID = pID;
					_recievedStream = new NetStream(_nc, _farID);
					_recievedStream.addEventListener(NetStatusEvent.NET_STATUS, recievedStreamClientHandler);
				}
				
				else
				{
					_recievedStream = new NetStream(_nc, _farID);
					_recievedStream.addEventListener(NetStatusEvent.NET_STATUS, recievedStreamServerHandler);
				}
			}
			//擂台模式下由攻方主动连接守方
			else
			{
				_leizhu = server;
				//擂主
				if (_leizhu == true)
				{
					_recievedStream = new NetStream(_nc, _farID);
					_recievedStream.addEventListener(NetStatusEvent.NET_STATUS, leizhuStreamHandler);
					if (_gongleiClock == null)
					{
						_gongleiClock = new Timer(1000);
					}
					_gongleiClock.repeatCount = replayTime;
					_gongleiClock.reset();
					_gongleiClock.addEventListener(TimerEvent.TIMER_COMPLETE, gongleiCloskCompleteHandler);
					_gongleiClock.start();
				}
				//攻擂方
				else
				{
					_farID = pID;
					_recievedStream = new NetStream(_nc, _farID);
					_recievedStream.addEventListener(NetStatusEvent.NET_STATUS, gongleiStreamHandler);
					if (_gongleiClock == null)
					{
						_gongleiClock = new Timer(1000);
					}
					_gongleiClock.repeatCount = replayTime;
					_gongleiClock.reset();
					_gongleiClock.addEventListener(TimerEvent.TIMER_COMPLETE, gongleiCloskCompleteHandler);
					_gongleiClock.start();
				}
			}
			_recievedStream.play("loojoy");
			
			var obj:Object = { };
			obj.dataHandler = function(msg:Object)
			{
				dispatchEvent(new P2PEvent(P2PEvent.P2P_DATA, false, msg));
			}
			_recievedStream.client = obj;
		}
		
		//攻擂方的超时设置
		private function gongleiCloskCompleteHandler(evt:TimerEvent)
		{
			_gongleiClock.removeEventListener(TimerEvent.TIMER_COMPLETE, gongleiCloskCompleteHandler);
			_gongleiClock.reset();
			var toPID:String = _farID;
			farID = null;
			recievedClose();
			dispatchEvent(new P2PEvent(P2PEvent.LEITAI_CONNECT_FAIL,false,{pID:toPID}));
		}
		
		//擂主的p2p事件
		private function leizhuStreamHandler(evt:NetStatusEvent)
		{
			//trace(RoleModel.getInstance().roleName,"擂主p2p事件:", evt.info.code);
			switch(evt.info.code)
			{
				//对方关闭了p2p连接
				case "NetStream.Play.UnpublishNotify":
				if (_gongleiClock != null)
				{
					_gongleiClock.reset();
					_gongleiClock.removeEventListener(TimerEvent.TIMER_COMPLETE, gongleiCloskCompleteHandler);
				}
				farID = null;
				recievedClose();
				dispatchEvent(new P2PEvent(P2PEvent.LEITAI_CLOSE));
				break;
				
				//由于没有授权p2p连接失败
				case "NetStream.Play.Failed":
				if (_gongleiClock != null)
				{
					_gongleiClock.reset();
					_gongleiClock.removeEventListener(TimerEvent.TIMER_COMPLETE, gongleiCloskCompleteHandler);
				}
				var toPID:String = _farID;
				farID = null;
				recievedClose();
				dispatchEvent(new P2PEvent(P2PEvent.LEITAI_CONNECT_FAIL,false,{pID:toPID}));
				break;
				
				//连接对方成功
				case "NetStream.Play.Start":
				//trace("擂台连接成功!!!!!!!!!!!!!!!!!!!!!!!!");
				if (_gongleiClock != null)
				{
					_gongleiClock.reset();
					_gongleiClock.removeEventListener(TimerEvent.TIMER_COMPLETE, gongleiCloskCompleteHandler);
				}
				dispatchEvent(new P2PEvent(P2PEvent.LEITAI_CONNECT_SUCCESS));
				break;
								
				default:
				//trace("没有处理事件");
			}
		}
		
		//攻擂者server
		private function gongleiStreamHandler(evt:NetStatusEvent)
		{
			//trace(RoleModel.getInstance().roleName,"攻擂者p2p事件:", evt.info.code);
			switch(evt.info.code)
			{
				//对方关闭了p2p连接
				case "NetStream.Play.UnpublishNotify":
				if (_gongleiClock != null)
				{
					_gongleiClock.reset();
					_gongleiClock.removeEventListener(TimerEvent.TIMER_COMPLETE, gongleiCloskCompleteHandler);
				}
				farID = null;
				recievedClose();
				dispatchEvent(new P2PEvent(P2PEvent.LEITAI_CLOSE));
				break;
				
				//由于没有授权p2p连接失败
				case "NetStream.Play.Failed":
				if (_gongleiClock != null)
				{
					_gongleiClock.reset();
					_gongleiClock.removeEventListener(TimerEvent.TIMER_COMPLETE, gongleiCloskCompleteHandler);
				}
				var toPID:String = _farID;
				farID = null;
				recievedClose();
				dispatchEvent(new P2PEvent(P2PEvent.LEITAI_CONNECT_FAIL,false,{pID:toPID}));
				break;
				
				//连接对方成功
				case "NetStream.Play.Start":
				//trace("连接擂主成功!!!!!!!!!!!!!!!!!!!!!!");
				if (_gongleiClock != null)
				{
					_gongleiClock.reset();
					_gongleiClock.removeEventListener(TimerEvent.TIMER_COMPLETE, gongleiCloskCompleteHandler);
				}
				dispatchEvent(new P2PEvent(P2PEvent.LEITAI_CONNECT_WAIT));
				break;
								
				default:
				//trace("没有处理事件");
			}
		}
		
		//应战方事件
		private function recievedStreamClientHandler(evt:NetStatusEvent)
		{
			//trace(RoleModel.getInstance().roleName,"recievedStreamClientHandler:", evt.info.code);
			switch(evt.info.code)
			{
				//对方关闭了p2p连接
				case "NetStream.Play.UnpublishNotify":
				//trace("对方关闭了p2p连接");
				farID = null;
				recievedClose();
				dispatchEvent(new P2PEvent(P2PEvent.P2P_CLOSE));
				break;
				
				//由于没有授权p2p连接失败
				case "NetStream.Play.Failed":
				//trace(RoleModel.getInstance().roleName,"与对方的p2p连接失败了client");
				var toPID:String = _farID;
				farID = null;
				recievedClose();
				dispatchEvent(new P2PEvent(P2PEvent.P2P_CONNECT_FAIL,false,{pID:toPID}));
				break;
				
				//连接对方成功
				case "NetStream.Play.Start":
				//trace("应战方连接成功，等待对方回复");
				dispatchEvent(new P2PEvent(P2PEvent.P2P_CONNECT_WAIT));
				break;
								
				default:
				//trace("没有处理事件");
			}
		}
		
		private function recievedStreamServerHandler(evt:NetStatusEvent)
		{
			//trace(RoleModel.getInstance().roleName,"recievedStreamServerHandler:", evt.info.code);
			switch(evt.info.code)
			{
				//对方关闭了p2p连接
				case "NetStream.Play.UnpublishNotify":
				//trace("对方关闭了p2p连接");
				farID = null;
				recievedClose();
				dispatchEvent(new P2PEvent(P2PEvent.P2P_CLOSE));
				break;
				
				//由于没有授权p2p连接失败
				case "NetStream.Play.Failed":
				//trace(RoleModel.getInstance().roleName,"与对方的p2p连接失败了server");
				var toPID:String = _farID;
				farID = null;
				recievedClose();
				dispatchEvent(new P2PEvent(P2PEvent.P2P_CONNECT_FAIL,false,{pID:toPID}));
				break;
				
				//连接对方成功
				case "NetStream.Play.Start":
				//trace("p2p双向联机成功");
				dispatchEvent(new P2PEvent(P2PEvent.P2P_CONNECT_SUCCESS));
				break;
				
				default:
				//trace("没有处理事件");
			}
		}
		
		public function p2pSend(msg:Object)
		{
			//trace(RoleModel.getInstance().roleName, "发送" + msg.head + "事件");
			if(_sendStream!=null)
			_sendStream.send("dataHandler", msg);
		}
		
		/**
		 * 是否为擂台模式
		 */
		public function get leitaiMode():Boolean
		{
			return _leitaiMode;
		}
		
		public function set leitaiMode(val:Boolean)
		{
			_leitaiMode = val;
		}
	}

}
class SingletonEnforcer{}