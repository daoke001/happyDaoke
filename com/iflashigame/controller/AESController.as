package com.iflashigame.controller 
{
	import com.adobe.serialization.json.JSON;
	import com.iflashigame.utils.AESTools;
	import com.iflashigame.utils.Tools;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.sendToURL;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	/**
	 * 通讯控制器类
	 * @author faster
	 */
	public class AESController extends EventDispatcher implements IController
	{
		private static var _instance:AESController;
		private static const KEY:String = "0315b6e6e482ff7e";
		private static const IV:String = "44b5618f44f1dfa9";
		
		private var _debug:Boolean = false;		//是否输出数据包字符串
		private var _test:Boolean = false;		//是否启用测试数据
		
		private var _root:DisplayObjectContainer;			//用于创建mask的主层，通常是main
		private var _maskDomain:ApplicationDomain;		//遮罩的域
		private var _maskCode:String;				//遮罩的编码
		private var _mask:MovieClip;				//遮挡层
		
		private var _maskRelative:String="";			//与遮罩关联的协议的时间戳
		private var _serverURL:String = "";		//服务器的请求地址
		
		
		private var _listeners:Object = { };	//处理缓存
		private var _fun:Object = { };			//用于存储每个发送包中包含的执行函数
		private var _funParamer:Object = { };	//用于存储每个发送包执行函数需要使用的参数
		
		private var _listenerCount:int = 0;		//缓存中处理函数的数量
		
		private var _timeOut:int = 180;		//响应过期时间	(单位：秒)
		private var _timer:Timer;
		
		private var _disable:Boolean;			//是否禁用通讯
		
		private var _testInstance:IControllerTest;		//用于数据测试的实例名
		
		private var _requestCode:String = "gbk";
		private var _responseCode:String = "utf-8";
		private var _codeStrack:Dictionary = new Dictionary;		//代码堆栈,包含stamp、head、code
		
		public function AESController(singletonEnforcer:SingletonEnforcer) 
		{
			_timer = new Timer(1000);
			_timer.addEventListener(TimerEvent.TIMER, onTimerHandler);
		}
		
		/**
		 * 取得单例
		 * @return
		 */
		public static function getInstance():IController
		{
			if (AESController._instance == null)
			{
				AESController._instance = new AESController(new SingletonEnforcer);
			}
			return AESController._instance;
		}
		
		/**
		 * 设置根类
		 * @param	root
		 */
		public function setRoot(root:DisplayObjectContainer,maskCode:String,maskDomain:ApplicationDomain=null)
		{
			_root = root;
			_maskCode = maskCode;
			_maskDomain = maskDomain == null?ApplicationDomain.currentDomain:maskDomain;
		}
		
		/**
		 * 取得服务器请求地址
		 */
		public function get serverURL():String
		{
			return _serverURL;
		}
		
		/**
		 * 设置服务器地址
		 */
		public function set serverURL(val:String)
		{
			_serverURL = val;
		}
		
		public function get debug():Boolean 
		{
			return _debug;
		}
		
		public function set debug(value:Boolean):void 
		{
			_debug = value;
		}
		
		public function get test():Boolean 
		{
			return _test;
		}
		
		public function set test(value:Boolean):void 
		{
			_test = value;
		}
		
		public function get testInstance():IControllerTest 
		{
			return _testInstance;
		}
		
		public function set testInstance(value:IControllerTest):void 
		{
			_testInstance = value;
		}
		
		public function get disable():Boolean 
		{
			return _disable;
		}
		
		public function set disable(value:Boolean):void 
		{
			_disable = value;
		}
		
		/**
		 * 向服务器发送请求
		 * @param	data	发送到服务器的数据包
		 * @param	listener	用来处理
		 * @param	url
		 * data数据除了自由定义的协议字段之外可以包括fun和funParamer字段
		 * data.fun和data.funParamer可以在接受到服务器返回数据之后，执行
		 * 特定的方法。方法体保存在data.fun中，方法参数保存在data.funParamer中
		 * 
		 * data.fun的使用方法：(data.fun as Function).apply(null, funParamer);
		 */
		public function sendJSON(data:Object, listener:Function, url:String = "" ):String
		{
			//通讯控制器被禁用
			if (_disable) return null;
			
			//时间戳
			var stamp:String=getTimer().toString()+Math.random().toFixed(5);
			data.stamp = stamp;
			var fun:Function = data.fun;
			var funParamer:Array = data.funParamer;
			delete data.fun;
			delete data.funParamer;
			
			//加载调试数据
			if (_test)
			{
				loadTestData(data,listener,fun,funParamer);
			}
			else
			{
				if (url == "")
				{
					send(data, listener, _serverURL,fun,funParamer);
				}
				else
				{
					send(data, listener, url,fun,funParamer);
				}
			}
			return stamp;
		}
		
		/**
		 * 发送数据无需等待返回
		 * @param	data
		 * @param	url
		 * @return
		 */
		public function sendJSONToURL(data:Object, url:String = ""):String
		{
			if (_disable) return null;
			var stamp:String = getTimer().toString() + Math.random().toFixed(5);
			data.stamp = stamp;
			
			var urlVariables:URLVariables = new URLVariables();   
			urlVariables.data = AESTools.encrypt(JSON.encode(data), KEY, IV,_requestCode);
			
			if (url == "") url = _serverURL;
			
			if (_debug)
			{
				trace("==========客户端发送数据(无需服务器反馈)===================")
				trace("发送到:", url);
				trace(JSON.encode(data));	//输出json字符串
				//trace(AESTools.encrypt(JSON.encode(data), KEY, IV,_requestCode));	//输出加密字符串
				trace("==========客户端数据发送完毕===================")
			}
			
			var urlRequest:URLRequest = new URLRequest();
			urlRequest.url = url;
			urlRequest.method = URLRequestMethod.POST;   
			urlRequest.data = urlVariables;   
 
			sendToURL(urlRequest);
			return stamp;
		}
		
		/**
		 * 关闭某个协议的侦听
		 * @param	stamp	需要关闭的协议的时间戳
		 */
		public function close(stamp:String)
		{
			if (_listeners.hasOwnProperty(stamp))
			{
				_listeners[stamp].instance.close();
				delete _listeners[stamp];
				delete _fun[stamp];
				delete _funParamer[stamp];
				_listenerCount--;
			}
		}
		
		/**
		 * 创建遮罩层
		 */
		private function createMask()
		{
			//如果遮罩还没有创建
			if (_mask == null)
			{
				//没有设定程序域或者编码
				if (_maskDomain == null || _maskCode == "") 
				{
					throw new Error("没有指定域或者遮罩编码为空，无法创建遮罩！");
					return;
				}
				
				var skinClass:Class = _maskDomain.getDefinition(_maskCode) as Class;
				_mask = (new skinClass()) as MovieClip;
				
				//没有设置显示容器，或者显示容器的stage为空
				if (_root == null || _root.stage == null) 
				{
					throw new Error("没有指定遮罩容器，无法创建遮罩");
					return;
				}
				_mask.graphics.beginFill(0, 0.4);
				_mask.graphics.drawRect( -_root.stage.stageWidth / 2, -_root.stage.stageHeight / 2,
											_root.stage.stageWidth, _root.stage.stageHeight);
				_mask.x = _root.stage.stageWidth / 2;
				_mask.y = _root.stage.stageHeight / 2;
			}
		}
		
		/**
		 * 发送数据请求
		 * @param	data	需要发送的数据包
		 * @param	listener	接收的处理函数
		 * @param	url		需要发送到的地址
		 */
		private function send(data:Object, listener:Function, url:String,fun:Function,funParamer:Array)
		{
			//以时间戳为标识记录处理器
			_listeners[data.stamp] = { fun:listener, count:_timeOut, head:data.head };
			_fun[data.stamp] = fun;
			_funParamer[data.stamp] = funParamer;
			
			
			//是否显示系统忙的遮罩
			if (data.mask == true)
			{
				//当前还没有遮罩
				if (_maskRelative == "")
				{
					createMask();
					if(_mask!=null)
					_root.addChild(_mask);
				}
				_maskRelative = data.stamp;
				delete data.mask;
			}
			
			//处理器缓存累加
			_listenerCount++;
			
			//启动计时器
			if (!_timer.running)	_timer.start();

			var urlVariables:URLVariables = new URLVariables();   
			urlVariables.data = AESTools.encrypt(JSON.encode(data), KEY, IV,_requestCode);
			
			if (_debug)
			{
				trace("==========客户端发送数据===================")
				trace("发送到:", _serverURL);
				trace(JSON.encode(data));
				//trace(AESTools.encrypt(JSON.encode(data), KEY, IV,requestCode));
				trace("==========客户端数据发送完毕===================")
			}
			
			var urlRequest:URLRequest = new URLRequest();
			urlRequest.url = url;
			urlRequest.method = URLRequestMethod.POST;   
			urlRequest.data = urlVariables;   
 
			var urlLoader:URLLoader = new URLLoader();  
			//记录urlLoader对象的引用
			_listeners[data.stamp].instance = urlLoader;
			_codeStrack[urlLoader] = { stamp:data.stamp, head:data.head,roleID:data.roleID };
			urlLoader.addEventListener(Event.COMPLETE, onURLLoaderCompleteHandler);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOErrorHandler);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityErrorHandler);
			urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatusHandler);
			urlLoader.load(urlRequest); 
		}
		
		/**
		 * 获取通讯的Http数据头
		 * @param	evt
		 */
		private function onHttpStatusHandler(evt:HTTPStatusEvent)
		{
			if (_codeStrack[evt.currentTarget] != null)
			{
				_codeStrack[evt.currentTarget].code = evt.status;
			}
			else
			{
				throw new Error("没有指定的dispatcher对象");
				return;
			}
		}
		
		/**
		 * 请求无法响应
		 * @param	evt
		 */
		private function onIOErrorHandler(evt:IOErrorEvent)
		{
			var code:String = _codeStrack[evt.currentTarget].code;
			var head:int = _codeStrack[evt.currentTarget].head;
			var stamp:String = _codeStrack[evt.currentTarget].stamp;
			var roleID:String = _codeStrack[evt.currentTarget].roleID;
			delete _codeStrack[evt.currentTarget];
			close(stamp);
			dispatchEvent(new ControllerEvent(ControllerEvent.ERROR, { text:"通讯错误，网络请求无法响应。错误码(" + code + "|" + head + "|" + roleID + ")" } ));
		}
		
		/**
		 * 请求出现安全错误
		 * @param	evt
		 */
		private function onSecurityErrorHandler(evt:SecurityErrorEvent)
		{
			dispatchEvent(new ControllerEvent(ControllerEvent.ERROR, { text:"安全错误，无法取得授权文件!"} ));
		}
		
		/**
		 * 计时器处理函数
		 * @param	evt
		 */
		private function onTimerHandler(evt:TimerEvent)
		{
			//处理缓存池已经清空
			if (_listenerCount <= 0)
			{
				trace("控制器的计时器已经停止");
				_timer.stop();
				_timer.reset();
				return;
			}
			
			for(var i in _listeners)
			{
				_listeners[i].count--;
				if(_listeners[i].count<=0)
				{
					dispatchEvent(new ControllerEvent(ControllerEvent.ERROR, { text:"请求服务器请求超时-"+_listeners[i].head } ));
					
					if (_maskRelative == i)
					{
						_maskRelative = "";
						_root.removeChild(_mask);
					}
					
					delete _codeStrack[_listeners[i].instance]
					close(i);
				}
			}
		}
		
		/**
		 * 接收的请求事件的返回数据
		 * @param	evt
		 */
		private function onURLLoaderCompleteHandler(evt:Event)
		{
			evt.currentTarget.removeEventListener(Event.COMPLETE, onURLLoaderCompleteHandler);
			evt.currentTarget.removeEventListener(IOErrorEvent.IO_ERROR, onIOErrorHandler);
			evt.currentTarget.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityErrorHandler);
			evt.currentTarget.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatusHandler);
			
			//trace("未解密信息:" + evt.target.data);
			//var str:String = AESTools.decrypt(URLLoader( evt.target ).data, KEY, IV,"gbk");
			var str:String = AESTools.decrypt(URLLoader( evt.target ).data, KEY, IV,_responseCode);
			if (_debug)
			{
				trace("==========服务器返回数据===================")
				trace(str);
				trace("==========服务器数据完毕===================")
			}
			var data:Object = JSON.decode(str);
			
			if (_listeners.hasOwnProperty(data.stamp))
			{
				//移除遮罩
				if (_maskRelative == data.stamp)
				{
					_maskRelative = "";
					_root.removeChild(_mask);
				}
				
				data.fun = _fun[data.stamp];
				data.funParamer = _funParamer[data.stamp];
				delete _fun[data.stamp];
				delete _funParamer[data.stamp];
				_listeners[data.stamp].fun(data);
				trace("移除计时器")
				delete _codeStrack[_listeners[data.stamp].instance]
				delete _listeners[data.stamp];
				_listenerCount--;
			}
			else
			{
				delete _codeStrack[_listeners[data.stamp].instance];
				close(data.stamp);
				_listenerCount--;
				throw new Error("返回的数据找不到回调方法");
				return;
			}
		}
		
		/**
		 * 测试数据的入口
		 * @param	event
		 * @param	listener
		 */
		private function loadTestData(data:Object, listener:Function,fun:Function,funParamer:Array)
		{
			//检测测试实例是否为空
			if (_testInstance == null) 
			{
				throw new Error("测试数据所用的实例为空");
				return;
			}
			
			data.fun = fun;
			data.funParamer = funParamer;
			var obj:Object = _testInstance.getData(data);
			if (debug)
			{
				trace("==========客户端发送数据===================")
				trace(JSON.encode(data));
				trace("==========客户端数据发送完毕===================")
				trace("==========收到模拟数据===================")
				trace(JSON.encode(obj));
				trace("==========模拟数据接收完毕===================")
			}
			listener(obj);
		}
		
		public function get requestCode():String
		{
			return _requestCode;
		}
		public function set requestCode(val:String)
		{
			_requestCode = val;
		}
		public function get responseCode():String
		{
			return _responseCode;
		}
		public function set responseCode(val:String)
		{
			_responseCode = val;
		}
	}
}
class SingletonEnforcer{}