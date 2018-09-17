package com.iflashigame.ui 
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.TextEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Rectangle;
	import flash.system.ApplicationDomain;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import game.ui.SkinCode;
	
	/**
	 * 提示信息框
	 * @author faster
	 */
	public class TipsFrame extends Sprite
	{
		protected var _tf:TextField;
		protected var _width:int = 155;
		protected var _height:int = 50;
		protected var _bordColor:uint = 0x000033;
		protected var _bodyColor:uint = 0x000033;
		protected var _bordAlpha:Number = 1;
		protected var _bodyAlpha:Number = 0.5;
		protected var _bordSize:Number = 2;
		
		protected var _focus:Boolean;
		
		public var type:int = 1;		//1=下方居中跟随  2=上方居中跟随  3=左顶点跟随
		public var star:int;
		
		public var _tff:TextFormat;
		protected var _starMC:MovieClip;
		
		public function TipsFrame() 
		{
			initView();
		}
		
		private function initView()
		{
			mouseEnabled = false;
			//mouseChildren = false;
			_tf = new TextField;
			_tf.textColor = 0xffffff;
			addChild(_tf);
			_tf.multiline = true;
			_tf.wordWrap = true;
			_tf.width = _width;
			_tf.selectable = false;
			
			_tff = new TextFormat();
			_tff.leading = 3;
			_tf.defaultTextFormat = _tff;
			
		}
		
		/**
		 * 数据初始化
		 * @param	obj
		 * obj.width  文本的宽度
		 * obj.height	先预留，不起作用
		 * obj.htmlText
		 * obj.bordColor
		 * obj.bodyColor
		 * obj.bordAlpha
		 * obj.bodyAlpha
		 * obj.bordSize
		 * obj.focus		是否让文本获得焦点
		 */
		public function initData(obj:Object)
		{
			//if (obj.hasOwnProperty("width")) _width = obj.width;
			if (obj.hasOwnProperty("height")) _height = obj.height;
			if (obj.hasOwnProperty("bordColor")) _bordColor = obj.bordColor;
			if (obj.hasOwnProperty("bodyColor")) _bodyColor = obj.bodyColor;
			if (obj.hasOwnProperty("bordAlpha")) _bordAlpha = obj.bordAlpha;
			if (obj.hasOwnProperty("bodyAlpha")) _bodyAlpha = obj.bodyAlpha;
			if (obj.hasOwnProperty("bordSize")) _bordSize = obj.bordSize;
			if (obj.hasOwnProperty("type")) type = obj.type;
			if (obj.hasOwnProperty("focus")) _focus = Boolean(obj.focus);
			if (obj.hasOwnProperty("star")) star = obj.star;
			else star = 0;
			
			_tf.text = "";
			_tf.textColor = 0xffffff;
			_tf.htmlText = obj.htmlText;
			_tf.width = _width;
			_tf.height = _height=_tf.textHeight+5;
			_tf.filters = [new GlowFilter(0, 0.6, 2, 2, 200)];
			
			_tf.x = 6;
			_tf.y = 6;
			graphics.clear();
			graphics.beginFill(_bodyColor, _bodyAlpha);
			graphics.lineStyle(_bordSize, _bordColor, _bordAlpha);
			graphics.drawRoundRect(0, 0, _width + 12, _height + 12, 5, 5);
			filters = [new DropShadowFilter(2, 45, 0, 0.5)]
			
			if (_starMC != null)
			{
				removeChild(_starMC);
				_starMC = null;
			}
			if (star != 0)
			{
				var starClass:Class = ApplicationDomain.currentDomain.getDefinition(SkinCode.STAR) as Class;
				_starMC = new starClass as MovieClip;
				_starMC.gotoAndStop(star);
				
				var count:int = _tf.getLineLength(0);
				var rec:Rectangle = _tf.getCharBoundaries(_tf.getLineLength(0) - 2)
				_starMC.x = rec.x+rec.width + 15;
				_starMC.y = rec.y+8;
				addChild(_starMC);
			}
			
		}
	}
}