package com.iflashigame.bitmap 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.system.ApplicationDomain;
	
	/**
	 * 缓存序列类
	 * @author Faster
	 */
	public class CacherList extends EventDispatcher 
	{
		private var _nameList:Vector.<String>;
		private var _mcList:Array;
		private var _frameCount:int;	//总帧数
		private var _currentFrame:int;	//当前已经处理的帧数
		
		private var _currentIndex:int;	//当前正在处理的mc的索引
		public function CacherList(list:Vector.<String>) 
		{
			_nameList = list;
			_mcList = [];
			for (var i:int = 0; i < list.length; i++)
			{
				_mcList.push(new (ApplicationDomain.currentDomain.getDefinition(list[i]) as Class) as MovieClip);
				_mcList[i].stop();
				_frameCount += _mcList[i].totalFrames;
			}
		}
		
		/**
		 * 开始预处理
		 */
		public function start()
		{
			_currentIndex = 0;
			_currentFrame = 0;
			processMC(_currentIndex);
		}
		
		private function processMC(index:int)
		{
			var cacher:Cacher = new Cacher();
			cacher.name = _nameList[index];
			cacher.addEventListener(Event.COMPLETE, onCacheCompleteHandler);
			cacher.addEventListener(ProgressEvent.PROGRESS, onCacherProgressHandler);
			cacher.cacheBitmapMovie(_mcList[_currentIndex], true, 0x00000000, 0.65);
		}
		
		private function onCacheCompleteHandler(evt:Event):void 
		{
			evt.currentTarget.removeEventListener(Event.COMPLETE, onCacheCompleteHandler);
			evt.currentTarget.removeEventListener(ProgressEvent.PROGRESS, onCacherProgressHandler);
			GlobalBitmapData.setData(evt.currentTarget.name, evt.currentTarget.bitmapSpriteInfo);
			_currentIndex++;
			if (_currentIndex == _nameList.length)
			{
				dispatchEvent(new Event(Event.COMPLETE));
			}
			else
			{
				processMC(_currentIndex);
			}
		}
		
		private function onCacherProgressHandler(evt:ProgressEvent):void 
		{
			_currentFrame++;
			if (_currentFrame > _frameCount) _currentFrame = _frameCount;
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, _currentFrame, _frameCount));
		}
	}
}