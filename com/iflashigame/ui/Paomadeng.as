package com.iflashigame.ui 
{
	import com.iflashigame.utils.Tools;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.Rectangle;
	import flash.system.ApplicationDomain;
	import flash.text.TextField;
	
	/**
	 * 跑马灯
	 * @author faster
	 */
	public class Paomadeng extends Sprite
	{
		private var _tf1:TextField;
		private var _tf2:TextField;
		private var _arr:Array;
		private var _recWidth:Number;
		private var _recHeight:Number;
		private var _speed:Number
		
		public function Paomadeng(arr:Array, recWidth:Number = 200, recHeight:Number = 16, speed:Number = 1,color:uint=0xeeeeee ) 
		{
			_arr = arr
			_recWidth = recWidth;
			_recHeight = recHeight;
			_speed = speed;
			
			_tf1 = new TextField();
			_tf1.textColor = color;
			_tf1.width = _recWidth;
			_tf1.height = _recHeight;
			_tf1.filters=[new GlowFilter(0,1,2,2,100)]
			
			_tf2 = new TextField;
			_tf2.width = _recWidth;
			_tf2.height = _recHeight;
			
			_tf2.x = _tf1.width;
			addChild(_tf1);
			addChild(_tf2);
			
			scrollRect = new Rectangle(0, 0, _recWidth, _recHeight);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemoveFromStageHandler);
		}
		
		public function start()
		{
			_tf1.removeEventListener(Event.ENTER_FRAME, onEnterFrameHandler1);
			_tf2.removeEventListener(Event.ENTER_FRAME, onEnterFrameHandler2);
			_tf1.x = _recWidth + 10;
			_tf2.x = _recWidth + 10;
			setText(1);
			_tf1.addEventListener(Event.ENTER_FRAME, onEnterFrameHandler1);
		}
		
		private function setText(index:int)
		{
			if (index == 1)
			{
				_tf1.text = Tools.randomFromArr(_arr);
				_tf1.width = _tf1.textWidth + 5;
				_tf1.height = _recHeight;
			}
			else if (index == 2)
			{
				_tf2.text = Tools.randomFromArr(_arr);
				_tf2.width = _tf2.textWidth + 5;
			}
		}
		
		private function onEnterFrameHandler1(evt:Event)
		{
			_tf1.x-=_speed;
			if (_tf1.x < -_tf1.width)
			{
				_tf1.x = _recWidth + 10;
				setText(1);
			}
		}
		
		private function onRemoveFromStageHandler(evt:Event)
		{
			stop();
		}
		
		private function stop()
		{
			_tf1.removeEventListener(Event.ENTER_FRAME, onEnterFrameHandler1);
			_tf2.removeEventListener(Event.ENTER_FRAME, onEnterFrameHandler2);
		}
		
		private function onEnterFrameHandler2(evt:Event)
		{
		}
	}
}