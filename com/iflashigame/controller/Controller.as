package com.iflashigame.controller 
{
	import com.adobe.serialization.json.JSON;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.ApplicationDomain;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	/**
	 * 通讯控制器类
	 * @author faster
	 */
	public class Controller extends EventDispatcher implements IController
	{
		private static var _instance:Controller;
		
		private var _debug:Boolean = false;		//是否输出数据包字符串
		private var _test:Boolean = false;		//是否为测试数据状态
		
		private var _root:DisplayObjectContainer;			//用于创建mask的主层，通常是main
		private var _maskDomain:ApplicationDomain;		//遮罩的域
		private var _maskCode:String;				//遮罩的编码
		private var _mask:MovieClip;				//遮挡层
		
		private var _maskRelative:String="";			//与遮罩关联的事件
		
		private var _serverURL:String = "";		//服务器的请求地址
		private var _listeners:Object = { };	//处理缓存
		private var _fun:Object = { };			//用于存储每个发送包中包含的执行函数
		private var _funParamer:Object = { };	//用于存储每个发送包执行函数需要使用的参数
		
		private var _listenerCount:int = 0;		//缓存中处理函数的数量
		
		private var _timeOut:int = 180;		//响应过期时间	(单位：秒)
		private var _timer:Timer;
		
		private var _disable:Boolean;			//是否禁用通讯
		
		private var _testInstance:IControllerTest;		//用于数据测试的实例名
		
		public function Controller(singletonEnforcer:SingletonEnforcer) 
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
			if (Controller._instance == null)
			{
				Controller._instance = new Controller(new SingletonEnforcer);
			}
			return Controller._instance;
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
		 * data数据出了自由定义的协议字段之外可以包括fun和funParamer字段
		 * data.fun和data.funParamer可以在接受到服务器返回数据之后，执行
		 * 特定的方法。方法体保存在data.fun中，方法参数保存在data.funParamer中
		 * 
		 * data.fun的使用方法：(data.fun as Function).apply(null, funParamer);
		 */
		public function sendJSON(data:Object, listener:Function, url:String = "" ):String;
		{
			//通讯控制器被禁用
			if (_disable) return;
			
			//时间戳
			var stamp:String= getTimer().toString()+Math.random().toFixed(10)+Math.random().toFixed(5);
			data.timeStamp = stamp;
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
			return stamp
		}
		
		public function close(stamp:String)
		{
			if (_listeners.hasOwnProperty(stamp))
			{
				_listeners[stamp].instance.close();
				delete _listeners[stamp];
				_listenerCount--;
			}
		}
		
		/**
		 * 创建遮罩层
		 */
		private function createMask()
		{
			//不需要显示遮罩
			if (_mask == null)
			{
				//没有设定程序域或者编码
				if (_maskDomain == null || _maskCode == "") return;
				
				var skinClass:Class = _maskDomain.getDefinition(_maskCode) as Class;
				_mask = (new skinClass()) as MovieClip;
				
				//没有设置显示容器，或者显示容器的stage为空
				if (_root == null || _root.stage == null) return;
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
			_listeners[data.timeStamp] = { fun:listener, count:_timeOut, event:data.event };
			_fun[data.timeStamp] = fun;
			_funParamer[data.timeStamp] = funParamer;
			
			
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
				_maskRelative = data.timeStamp;
				delete data.mask;
			}
			
			//处理器缓存累加
			_listenerCount++;
			
			//启动计时器
			if (!_timer.running)	_timer.start();

			var urlVariables:URLVariables = new URLVariables();   
			urlVariables.json = JSON.encode(data);
			
			if (_debug)
			{
				trace("==========客户端发送数据===================")
				trace(urlVariables.json);
				trace("==========客户端数据发送完毕===================")
			}
			
			var urlRequest:URLRequest = new URLRequest();
			urlRequest.url = url;
			urlRequest.method = URLRequestMethod.POST;   
			urlRequest.data = urlVariables;   
 
			var urlLoader:URLLoader = new URLLoader(); 
			_listeners[data.timeStamp].instance = urlLoader;
			urlLoader.addEventListener(Event.COMPLETE, onURLLoaderCompleteHandler);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOErrorHandler);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityErrorHandler);
			urlLoader.load(urlRequest); 
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
					trace(_listeners[i].event + "事件请求超时");
					
					dispatchEvent(new ControllerEvent(ControllerEvent.ERROR, { text:"连接服务器超时" } ));
					
					if (_maskRelative == i)
					{
						_maskRelative = "";
						_root.removeChild(_mask);
					}
					
					delete _listeners[i];
					delete _fun[i];
					delete _funParamer[i];
					_listenerCount--;
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
			
			if (_debug)
			{
				trace("==========服务器返回数据===================")
				trace(URLLoader( evt.target ).data);
				trace("==========服务器数据完毕===================")
			}
			var data:Object = JSON.decode(URLLoader( evt.target ).data);
			
			if (_listeners.hasOwnProperty(data.timeStamp))
			{
				if (_maskRelative == data.timeStamp)
				{
					_maskRelative = "";
					_root.removeChild(_mask);
				}
				
				data.fun = _fun[data.timeStamp];
				data.funParamer = _funParamer[data.timeStamp];
				delete _fun[data.timeStamp];
				delete _funParamer[data.timeStamp];
				_listeners[data.timeStamp].fun(data);
				trace("移除计时器")
				delete _listeners[data.timeStamp];
				_listenerCount--;
			}
			else
			{
				trace("返回的数据没有找到对应的处理函数");
			}
		}
		
		/**
		 * 请求无法响应
		 * @param	evt
		 */
		private function onIOErrorHandler(evt:IOErrorEvent)
		{
			trace("请求地址无效", evt.toString());
		}
		
		/**
		 * 请求出现安全错误
		 * @param	evt
		 */
		private function onSecurityErrorHandler(evt:SecurityErrorEvent)
		{
			trace("请求时出现安全错误", evt.toString());
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
			
			if (debug)
			{
				trace("==========客户端发送数据===================")
				trace(JSON.encode(data));
				trace("==========客户端数据发送完毕===================")
			}
			data.fun = fun;
			data.funParamer = funParamer;
			var obj:Object = _testInstance.getData(data);
			trace("==========收到模拟数据===================")
			trace(JSON.encode(obj));
			trace("==========模拟数据接收完毕===================")
			listener(obj);
		}
		
		public function get requestCode():String
		{
		}
		public function set requestCode(val:String)
		{
		}
		public function get responseCode():String
		{
		}
		public function set responseCode(val:String)
		{
		}
	}
}
class SingletonEnforcer{}