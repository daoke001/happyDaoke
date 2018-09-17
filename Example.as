package {
    import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

    public class Example extends Sprite {
        private var socket:mySocket;
		
		private var _timer:Timer;
		private var _maxTime:int = 1;	//连接服务器的等待时间
		public static const DELAY:int = 10000;
		private var i:int = 0;
        
        public function Example() {
            socket = new mySocket();
			socket.debug = true;
			socket.timeout = 1;
			socket.addEventListener("connected", socketConnectedHandler);
			socket.addEventListener("deconnected", socketDeconnectedHandler);
			socket.addEventListener("recievedData", socketRecieveHandler);
			var obj:Object = { Event:"c_checkMina", roleID:"roleID" };
			socket.connectServer("192.168.2.6", 8080, obj);
			
			_timer = new Timer(_maxTime, DELAY);
			
			//_timer.addEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
			_timer.addEventListener(TimerEvent.TIMER, timerHandler);
			
        }
		/**
		 * 连接超时
		 * @param	evt
		 */
		private function timerHandler(evt:TimerEvent)
		{
			var obj:Object;
			//for (var i:int = 0; i < 2; i++)
			{
				obj = { Event:"c_heart", roleID:"roleID" + i++ };
				socket.send(obj);
			}
		}
		/**
		 * socket连接成功
		 * @param	evt
		 */
		private function socketConnectedHandler(evt:Event):void 
		{
			//sendHeart();
			//_timer.start();
		}
		
		/**
		 * socket断开
		 * @param	evt
		 */
		private function socketDeconnectedHandler(evt:Event):void 
		{
			trace("socket 连接失败");
		}

		/**
		 * 发送心跳
		 */
		private function sendHeart()
		{
			var obj:Object;
			//for (var i:int = 0; i < 20; i++)
			//{
				//obj = { Event:"c_heart", roleID:"roleID" + i };
				//socket.send(obj);
			//}
		}
		
		/**
		 * 接收到socket信息
		 * @param	evt
		 */
		private function socketRecieveHandler(evt:Event):void 
		{
			var obj:Object = socket.getData();
			if (obj != null)
			{
				trace(obj.Event);
				switch(obj.Event)
				{
					//显示通告
					case "c_heart":
						trace("c_heart123445666");
						break;
						
				}
			}
		}
    }
}