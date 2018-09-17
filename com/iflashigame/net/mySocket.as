package com.iflashigame.net
{
	import flash.display.DisplayObjectContainer;
	import flash.events.TimerEvent;
	import flash.net.Socket;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.ProgressEvent;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	/**
	 * 游戏通讯类
	 * 封装了Socket 任何时候接收到数据都会抛出"recievedData"事件
	 * 独立的公开方法有三个 connectServer send getData();
	 */
	public class mySocket extends Socket
	{
		private var _loginData:Object;//登陆数据
		private var _dataArray:Array;//数据包堆栈
		private var _length:Number;//数据包的长度
		private var _readFlag:int;//0表示全部读完了，1表示等待读取长度，2表示长度读取完毕 3表示正在读取数据
		
		private var _timer:Timer;
		private var _maxTime:int = 1000;	//连接服务器的等待时间
		public static const DELAY:int = 10;
		
		private var _root:DisplayObjectContainer;
		private var _maskCode:String;
		private var _maskDomain:ApplicationDomain;
		/**
		 * 初始化函数，创建一个mySocket对象
		 */
		//public function mySocket(root:DisplayObjectContainer,maskCode:String,maskDomain:ApplicationDomain=null)
		public function mySocket()
		{
			super();
			
			//_root = root;
			//_maskCode = maskCode;
			//_maskDomain = maskDomain == null? ApplicationDomain.currentDomain:maskDomain;
			
			_loginData = new Object();
			_dataArray = new Array();
			_timer = new Timer(_maxTime, DELAY);
			
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
			
			addEventListener(Event.CONNECT, connectHandler);
			addEventListener(Event.CLOSE, closeHandler);
			addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
		
		}
		/**
		 * 连接到指定主机的端口
		 * @param	host 主机名
		 * @param	port 端口
		 * @param	loginData 登陆时发送到服务器的信息. 
		 * 结构为：Event 字符串"C_LoginRequest" roleID int型  checkCode 字符串
		 */
		public function connectServer(host:String, port:int,loginData:Object=null):void
		{
			_loginData = loginData;
			connect(host, port);
			_timer.start();
		}
		/**
		 * 发送一个对象到服务器
		 * @param	data 需要发送的Object类型对象
		 */
		public function send(data:Object)
		{
			var sendObj:ByteArray = cloneObject(data);
			trace("准备发送");
			if (connected == true)
			{
				writeObject(sendObj);
				flush();
				trace("发送完毕");
			}
			else
			{
				throw new Error("发送失败，原因是socket服务器没有连接");
			}
		}
		
		/**
		 * 连接超时
		 * @param	evt
		 */
		private function timerCompleteHandler(evt:TimerEvent)
		{
			_timer.stop();
			_timer.reset();
			throw new Error("socket服务器超时");
		}
		/**
		 * 连接成功
		 * @param	event
		 */
		private function connectHandler(event:Event):void
		{
			//10秒钟内连接成功，取消计时
			_timer.stop();
			_timer.reset();
			
			if(_loginData)
			send(_loginData);
			dispatchEvent(new Event("connected"));
		}
		private function closeHandler(event:Event):void
		{
			dispatchEvent(new Event("deconnected"));
		}
		private function ioErrorHandler(event:IOErrorEvent):void
		{
			trace("io错误");
		}
		private function securityErrorHandler(event:SecurityErrorEvent):void
		{
			trace("安全错误");
		}
		private function socketDataHandler(event:ProgressEvent):void
		{
			//_readFlag:int;//0表示全部读完了，1表示长度读取完毕 2表示正在读取数据
			trace("接收到数据");
			if (_readFlag==0&&bytesAvailable >= 4)
			{
				_length = readInt();
				_readFlag = 1;
			}
			if (_readFlag==1&&bytesAvailable >= _length)
			{
				readData(_length);
			}
		}
		private function readData(dataLength:Number)
		{
			_readFlag = 2;
			var temp:Object = readObject();
			_dataArray.push(temp);
			dispatchEvent(new Event("recievedData"));
			_length = 0;
			if (bytesAvailable >= 4)
			{
				_length = readInt();
			}			
			if (_length!=0&&bytesAvailable >= _length)
			{
				readData(_length);
			}			
			else
			{
				_readFlag = 0;
			}
		}
		/**
		 * 返回数据堆栈中最前一个对象
		 * @return 数据堆栈中的对象
		 */
		public function getData():Object
		{
			if (_dataArray.length != 0)
			{
				var tmp:Object = _dataArray[0];
				_dataArray.shift();
				return tmp;
			}
			else
				return null;
		}
		public function get length():int
		{
			return _dataArray.length;
		}
		private function cloneObject(obj:Object):ByteArray
		{
			var bytesArray:ByteArray = new ByteArray();
			bytesArray.writeObject(obj);
			bytesArray.position=0;
			
			var tmp:ByteArray=new ByteArray();
			tmp.writeObject(bytesArray);
			tmp.position=0;
			//trace("开始打印数据包的长度",tmp.length);
			//for(var i=0;i<tmp.length;i++)
			//{
				//trace(tmp.readUnsignedByte().toString(16));
			//}
			//trace("数据包打印结束");
			return bytesArray;
		}
		public function get currentCount():int
		{
			return _timer.currentCount;
		}
	}
	
}