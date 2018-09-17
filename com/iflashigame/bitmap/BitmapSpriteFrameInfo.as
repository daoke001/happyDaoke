package com.iflashigame.bitmap 
{
	import flash.display.BitmapData;
	/**
	 * 精灵位图动画单帧数据类
	 * @author Faster
	 */
	public class BitmapSpriteFrameInfo 
	{
		public var x:Number;
		public var y:Number;
		public var data:BitmapData;
		
		/**
		 * 下一个位图信息。如果为-1,则播放停止
		 */
		public var next:int=-1;	
		/**
		 * 帧标签
		 */
		public var label:String = "";	
		/**
		 * 表示位图占用的帧数，如果delay=2表示此位图占用两帧
		 */
		public var delay:int = 1;
		
		private var _event:Vector.<String>;
		private var _bubbles:Vector.<Boolean>;
		
		/**
		 * 单帧位图数据初始化
		 * @param	data	单帧位图
		 * @param	x		x坐标
		 * @param	y		y坐标
		 * @param	next	下一帧的帧数	如果为-1则停在此帧
		 * @param	label	帧标签
		 * @param	delay	占用帧数
		 */
		public function BitmapSpriteFrameInfo(data:BitmapData=null, x:Number = 0, y:Number = 0,
											next:int=-1,label:String="",delay:int=1) 
		{
			this.data = data;
			this.x = x;
			this.y = y;
			this.next = next;
			this.label = label;
			this.delay = delay;
			_event = new Vector.<String>;
			_bubbles = new Vector.<Boolean>;
		}
		
		/**
		 * 添加事件
		 * @param	evt
		 */
		public function addEvent(evt:String,bubbles:Boolean=false)
		{
			if (_event.indexOf(evt) == -1)
			{
				_event.push(evt);
				_bubbles.push(bubbles);
			}
		}
		
		/**
		 * 取得事件
		 * @param	index
		 * @return	{event,bubbles}
		 */
		public function getEvent(index:int):Object
		{
			return { event:_event[index], bubbles:_bubbles[index] };
		}
		
		/**
		 * 获取事件的数量
		 * @return
		 */
		public function get totalEvents():int
		{
			return _event.length;
		}
		
		/**
		 * 释放位图内存
		 */
		public function clear()
		{
			if (data != null)
			data.dispose();
			data = null;
		}
		
		public function toString():String
		{
			if(_event.length==0)
			return "x=" + x + ", y=" + y + ", label=\"" + label + "\", next=" + next + ", event=[" + _event.join("\",\"") + "], bubbles=["+_bubbles+"]";
			else
			return "x=" + x + ", y=" + y + ", label=\"" + label + "\", next=" + next + ", event=[\"" + _event.join("\",\"") + "\"], bubbles=["+_bubbles+"]";
		}
		
	}

}