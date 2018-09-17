package com.iflashigame.bitmap 
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	/**
	 * 位图精灵动画类
	 * @author Faster
	 */
	public class BitmapSprite extends Sprite
	{
		private var _data:BitmapSpriteInfo;	//动画数据信息
		private var _bitmap:Bitmap;
		
		private var _isPlaying:Boolean;		//是否为播放状态
		private var _currentIndex:int;
		private var _maxIndex:int;
		private var _currentFrameInfo:BitmapSpriteFrameInfo;
		
		public function BitmapSprite(data:BitmapSpriteInfo) 
		{
			_bitmap = new Bitmap();
			
			init()
			this.data = data;
			
			addEventListener(Event.ADDED_TO_STAGE, update);
			addEventListener(Event.REMOVED_FROM_STAGE, update);
		}
		
		private function init()
		{
			addChild(_bitmap);
			
			_currentIndex = 0;
			_maxIndex = 0;
			
			play();
		}
		
		/**
		 * 预览模式，无视帧控制代码
		 */
		public function playView():void
		{
			gotoAndStop(1);
			addEventListener(Event.REMOVED_FROM_STAGE,removePlayView)
			addEventListener(Event.ENTER_FRAME, playViewHandler);
		}
		
		public function stopView():void
		{
			removePlayView(null);
		}
		
		private function removePlayView(evt:Event):void
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, removePlayView)
			removeEventListener(Event.ENTER_FRAME, playViewHandler);
		}
		
		private function playViewHandler(evt:Event):void 
		{
			if (_currentIndex == _maxIndex)
			gotoFrame(0);
			else
			gotoFrame(_currentIndex+1);
		}
		
		/**
		 * 播放
		 */
		public function play():void
		{
			_isPlaying = true;
			update();
		}
		
		/**
		 * 停止
		 */
		public function stop():void
		{
			_isPlaying = false;
			update();
		}
		
		private function update(evt:Event = null):void
		{
			if (_isPlaying && _maxIndex != 0 && stage != null)
			{
				addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			}
			else
			{
				removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			}
		}
		
		/**
		 * 跳转到下一帧
		 */
		public function nextFrame():void
		{
			gotoFrame(_currentFrameInfo.next);
		}
		
		/**
		 * 跳转到指定帧并播放
		 * @param	frameIndex
		 */
		public function gotoAndPlay(frame:Object):void
		{
			//按帧信息还是按帧索引
			if (frame is String)
			{
				var index:int = _data.findLabel(String(frame));
				if (index != -1)
				{
					//trace(index + 1);
					goto(index+1);
					play();
				}
			}
			else
			{
				//trace(int(frame) + 1);
				goto(int(frame));
				play();
			}
		}
		
		/**
		 * 跳转到指定帧并停止
		 * @param	frameIndex
		 */
		public function gotoAndStop(frame:Object):void
		{
			//按帧信息还是按帧索引
			if (frame is String)
			{
				var index:int = _data.findLabel(String(frame));
				if (index != -1)
				{
					//trace(index + 1);
					goto(index+1);
					stop();
				}
			}
			else
			{
				//trace(int(frame) + 1);
				goto(int(frame));
				stop();
			}
		}
		
		/**
		 * 跳转到指定帧
		 * @param	frameIndex
		 */
		private function goto(frameIndex:int):void
		{
			///用户指定的帧数从1开始，程序内部的数组索引从0开始  因此减1
			gotoFrame(frameIndex - 1);
		}
		
		private function enterFrameHandler(evt:Event):void
		{
			nextFrame();
		}
		
		public function get data():BitmapSpriteInfo
		{
			return _data;
		}
		
		public function set data(data:BitmapSpriteInfo)
		{
			_data = data;
			
			_bitmap.bitmapData = null;
			
			if (_data == null)
			{
				_currentIndex = 0;
				_maxIndex = 0;
				update();
			}
			else
			{
				_maxIndex = _data.frameCount - 1;
				gotoFrame(_currentIndex);
				update();
			}
		}
		
		/**
		 * 跳转到指定索引的帧
		 * @param	frameIndex
		 */
		private function gotoFrame(frameIndex:int):void
		{
			if (frameIndex == -1)
			{
				stop();
				return;
			}
			
			_currentIndex = frameIndex;
			if (_currentIndex > _maxIndex)
			{
				_currentIndex = _maxIndex;
			}
			else if (_currentIndex < 0)
			{
				_currentIndex = 0;
			}
			
			_currentFrameInfo = _data.getAt(_currentIndex);
			_bitmap.bitmapData = _currentFrameInfo.data;
			_bitmap.x = _currentFrameInfo.x;
			_bitmap.y = _currentFrameInfo.y;
			
			var length:int = _currentFrameInfo.totalEvents;
			for (var i:int = 0; i < length; i++)
			{
				var obj:Object = _currentFrameInfo.getEvent(i);
				dispatchEvent(new Event(obj.event,obj.bubbles));
			}
		}
		
		/**
		 * 获取当前帧索引
		 */
		public function get currentFrame():int
		{
			///用户指定的帧数从1开始，程序内部的数组索引从0开始  因此加1
			return _currentIndex + 1;
		}
		
		/**
		 * 获取当前的帧标签
		 */
		public function get currentFrameLabel():String
		{
			return _currentFrameInfo == null?"":_currentFrameInfo.label;
		}
		
		/**
		 * 获取总的帧数
		 */
		public function get totalFrames():int
		{
			return _data == null ? 0 : _maxIndex + 1;
		}
		
		/**
		 * 获取或设置位图是否启用平滑处理
		 */
		public function get smoothing():Boolean 
		{ 
			return _bitmap.smoothing; 
		}
		
		public function set smoothing(value:Boolean):void 
		{
			_bitmap.smoothing = value;
		}
		
		/**
		 * 指示动画当前是否正在播放
		 */
		public function get isPlaying():Boolean 
		{
			return _isPlaying;
		}
		
		/**
		 * 销毁对象，释放资源
		 */
		public function clear()
		{
			stop();
			
			data = null;
			
			if(contains(_bitmap))
			removeChild(_bitmap);
		}
	}
}