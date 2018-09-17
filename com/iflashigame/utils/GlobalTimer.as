package com.iflashigame.utils 
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	/**
	 * 全局定时触发器
	 * @author 闪刀浪子
	 */
	public class GlobalTimer
	{
		
		private static var _instance:GlobalTimer;
		
		private var _timer:Timer;
		private var _lsManager:Object;		//定时触发管理器
		
		private var _count:int;		//触发器的数量
		private var _maxCount:int = 30;		//触发器的上限
		
		private var _defaultDelay:Number = 1000;
		
		public function GlobalTimer(singletonEnforcer:SingletonEnforcer) 
		{
			init();
		}
		
		/**
		 * 取得实例
		 * @return
		 */
		public static function getInstance():GlobalTimer
		{
			if (GlobalTimer._instance == null)
			{
				GlobalTimer._instance = new GlobalTimer(new SingletonEnforcer);
			}
			return GlobalTimer._instance;
		}
		
		/**
		 * 初始化计时器
		 */
		private function init()
		{
			_timer = new Timer(1000);
			_lsManager = { };
		}
		
		/**
		 * 启动触发器
		 */
		public function start()
		{
			if (_timer.running == false)
			{
				_timer.start();
				if (_timer.hasEventListener(TimerEvent.TIMER) == false)
				{
					_timer.addEventListener(TimerEvent.TIMER,onTimerEventHandler);
				}
			}
		}
		
		/**
		 * 触发器事件方法
		 * @param	evt
		 */
		private function onTimerEventHandler(evt:TimerEvent)
		{
			var arr:Array = [];
			for (var i in _lsManager)
			{
				var currentCount:int = _timer.currentCount;
				//时辰已到，开始触发
				if (_lsManager[i].nextCount <= currentCount)
				{
					_lsManager[i].nextCount = currentCount + _lsManager[i].delay;
					
					if (_lsManager[i].kill == true)
					{
						arr.push(i);
					}
					//已经暂停的不会触发
					else if (_lsManager[i].pause == false)
					{
						if(_lsManager[i].funObj==null)
						_lsManager[i].fun();
						else
						_lsManager[i].fun(_lsManager[i].funObj);
						
						_lsManager[i].currentRepeat++;
						//计算需要移除的计时器
						if (_lsManager[i].repeat != 0)
						{
							if (_lsManager[i].currentRepeat >= _lsManager[i].repeat)
							{
								_lsManager[i].kill = true;
								arr.push(i);
							}
						}
					}
				}
			}
			
			//移除到达次数的触发器
			for (var j:int = 0; j < arr.length; j++)
			{
				if (_lsManager[arr[j]].kill == true)
				{
					if (_lsManager[arr[j]].comFun != null)
					{
						if (_lsManager[arr[j]].comFunObj != null)
						{
							_lsManager[arr[j]].comFun(_lsManager[arr[j]].comFunObj);
						}
						else
						{
							_lsManager[arr[j]].comFun();
						}
					}
					_lsManager[arr[j]].fun = null;
					_lsManager[arr[j]].funObj = null;
					_lsManager[arr[j]].comFun = null;
					_lsManager[arr[j]].comFunObj = null;
					delete _lsManager[arr[j]];
				}
			}
		}
		
		/**
		 * 停止计时器
		 */
		public function stop()
		{
			_timer.stop();
		}
		
		public function reset()
		{
			_timer.reset();
		}
		
		/**
		 * 添加定时触发行为
		 * @param	lsName	触发器的名称
		 * @param	delay	触发器的时间间隔(秒)
		 * @param	repeat	触发器的循环次数 0表示无限循环
		 * @param	fun		触发器的回调函数
		 * @param	funObj	触发器回调函数需要的参数
		 * @param	comFun	触发完成后的回调函数
		 * @param	comFunObj	触发完成后的回调函数所需要的参数
		 */
		public function addListener(lsName:String, delay:int, fun:Function, repeat:int = 0, funObj:Object = null,
										comFun:Function=null,comFunObj:Object=null)
		{
			if (_count >= _maxCount)
			{
				throw new Error("触发器数量已达到上限!");
			}
			else if (_lsManager[lsName] == null)
			{
				//时间间隔、下次触发时间、是否暂停、回到函数
				_lsManager[lsName] = { delay:delay, nextCount:_timer.currentCount + delay, repeat:repeat, currentRepeat:0, pause:false,
										fun:fun,funObj:funObj,kill:false ,comFun:comFun,comFunObj:comFunObj}
				_count++;
			}
			//触发器已经存在
			else
			{
				_lsManager[lsName] = { delay:delay, nextCount:_timer.currentCount + delay, repeat:repeat, currentRepeat:0, pause:false,
										fun:fun,funObj:funObj,kill:false,comFun:comFun,comFunObj:comFunObj }
			}
		}
		
		/**
		 * 暂停触发事件
		 * @param	lsName
		 */
		public function pauseListener(lsName:String)
		{
			if (_lsManager[lsName] == null) return;
			_lsManager[lsName].pause = true;
		}
		
		/**
		 * 继续触发事件
		 * @param	lsName
		 */
		public function playListener(lsName:String)
		{
			if (_lsManager[lsName] == null) return;
			_lsManager[lsName].pause = false;
		}
		
		/**
		 * 移除定时触发
		 * @param	lsName
		 */
		public function removeListener(lsName:String)
		{
			//触发器不存在
			if (_lsManager[lsName] == null) return;
			_lsManager[lsName].kill = true;
			
			_count--;
		}
		
		public function hasListener(lsName:String):Boolean
		{
			if (_lsManager[lsName] == null)	return false;
			else if (_lsManager[lsName] != null && _lsManager[lsName].kill == true) return false;
			else return true;
		}
		
		public function get count():int
		{
			return _count;
		}
		
		public function get maxCount():int
		{
			return _maxCount;
		}
		//设置加速
		public function setSpeed(beishu:Number=1)
		{
			_timer.delay = _defaultDelay / beishu;
		}
		
		public function resetSpeed()
		{
			_timer.delay = _defaultDelay;
		}
	}
}
class SingletonEnforcer{}