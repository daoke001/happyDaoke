package 
{
	import com.adobe.serialization.json.JSON;
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
	 * 游戏 socket 通讯类
	 * 封装了Socket 任何时候接收到数据都会抛出"recievedData"事件
	 * 独立的公开方法有三个 connectServer send getData();
	 */
	public class mySocket extends Socket
	{
		private var _loginData:Object;	//登陆数据
		private var _dataArray:Array;	//数据包堆栈
		private var _length:Number;		//数据包的长度
		private var _readFlag:int;		//0表示全部读完了，1表示等待读取长度，2表示长度读取完毕 3表示正在读取数据
		
		private var _timer:Timer;
		private var _delayTime:int = 1000;	//连接服务器的等待时间
		public static const REPEAT:int = 10;	//重复次数
		
		private var _debug:Boolean = false; //是否输出数据包字符串
		
		/**
		 * 初始化函数，创建一个mySocket对象
		 */
		public function mySocket()
		{
			super();
			
			_loginData = new Object();
			_dataArray = new Array();
			
			_timer = new Timer(_delayTime, REPEAT);			
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
		public function connectServer(host:String, port:int, loginData:Object = null):void
		{
			_loginData = loginData;
			connect(host, port);
			_timer.start();
		}
		/**
		 * 发送一个二进制数据到服务器
		 * @param	data 需要发送的Object类型对象
		 */
		public function send(data:Object)
		{
			var sendObj:ByteArray = cloneObject(data);
			if (_debug)
			{
				trace("==========客户端发送数据(socket)===================")
				trace(JSON.stringify(data)); //输出json字符串
				trace("==========客户端数据(socket)发送完毕===============\n")
			}
			if (connected == true)
			{
				writeBytes(sendObj);	//发送二进制数据
				flush();
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
			
			if (_loginData)
			{
				send(_loginData);	//发送登录数据
			}
			dispatchEvent(new Event("connected"));
		}
		//socket断开
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
		/**
		 * 接到数据
		 * _readFlag 0表示全部读完了，1表示长度读取完毕 2表示正在读取数据
		 */
		private function socketDataHandler(event:ProgressEvent):void
		{
			if (_readFlag == 0 && bytesAvailable >= 4)
			{
				_length = readInt();
				_readFlag = 1;
			}
			if (_readFlag == 1 && bytesAvailable >= _length)
			{
				readData(_length);
			}
		}
		//读取数据
		private function readData(dataLength:Number):void
		{
			_readFlag = 2;
			var temp:ByteArray = new ByteArray();
			readBytes(temp, 0, dataLength);	//读取数据进入堆栈
			_dataArray.push(temp);
			dispatchEvent(new Event("recievedData"));
			_length = 0;
			
			if (bytesAvailable >= 4) _length = readInt();
			
			if (_length != 0 && bytesAvailable >= _length) readData(_length);
			else _readFlag = 0;
		}
		/**
		 * 返回数据堆栈中最前一个对象
		 * @return 数据堆栈中的对象
		 */
		public function getData():Object
		{
			if (_dataArray.length != 0)
			{
				var bytes:ByteArray = _dataArray[0];
				_dataArray.shift();
				var obj:Object = bytes.readObject();
				if (_debug)
				{
					trace("==========服务器发送数据(socket)===================")
					trace(JSON.stringify(obj)); //输出json字符串
					trace("==========服务器数据(socket)发送完毕===============\n")
				}
				return obj;
			}
			else return null;
		}
		
		private function cloneObject(obj:Object):ByteArray
		{
			var objByte:ByteArray = new ByteArray();  
			objByte.writeObject(obj);
			
			var bytesArray:ByteArray = new ByteArray();
			bytesArray.writeInt(objByte.length);	//写入正文长度  
			bytesArray.writeBytes(objByte, 0, objByte.length);	//写入正文
			bytesArray.position = 0;
			
			//var tmp:ByteArray=new ByteArray();
			//tmp.writeObject(obj);
			//tmp.position = 0;
			//trace("数据包的长度: ",tmp.length);
			//for (var i = 0; i < tmp.length; i++)
			//{
				//trace(tmp.readUnsignedByte().toString(16));
			//}
			//trace("数据包打印结束");
			
			return bytesArray;
		}
		
		//获取堆栈长度
		public function get length():int
		{
			return _dataArray.length;
		}
		//调试模式
		public function get debug():Boolean
		{
			return _debug;
		}		
		public function set debug(value:Boolean):void
		{
			_debug = value;
		}
	}
	
}