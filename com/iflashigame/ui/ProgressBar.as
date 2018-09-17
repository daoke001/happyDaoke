package com.iflashigame.ui 
{
	import flash.display.Shape;
	import flash.display.Sprite;
	
	/**
	 * 进度条类
	 * @author faster
	 */
	public class ProgressBar extends Sprite
	{
		private var _width:int;			//宽度
		private var _height:int;		//高度
		private var _fillType:int;		//填充方式
		private var _barColor:uint;		//填充颜色
		private var _barAlpha:Number;	//填充透明度
		private var _lineColor:uint;	//线框颜色
		private var _lineAlpha:Number;	//线框透明度
		private var _lineWidth:Number;	//线框宽度
		private var _fillColor:uint;	//
		private var _fillAlpha:Number;
		
		private var _bk:Shape;
		private var _bar:Shape;
		
		private var _max:Number = 100;
		private var _current:Number = 100;
		
		/**
		 * 构造函数
		 * @param	width		进度条的宽度
		 * @param	height		进度条的高度
		 * @param	fillType	填充方式1=纯色填充  2=方格填充 默认为1
		 * @param	barColor	进度条颜色，默认为0xff0000
		 * @param	barAlpha	进度的透明度
		 * @param	lineColor	线框颜色
		 * @param	lineAlpha	线框透明度
		 * @param	lineWidth	线框宽度
		 * @param	fillColor	填充色
		 * @param	fillAhpha	填充透明度
		 */
		public function ProgressBar(width:int, height:int, fillType:int = 1, barColor:uint = 0xff0000, barAlpha:Number = 1,
									lineColor:uint = 0xdddddd, lineAlpha:Number = 1,lineWidth:Number=1,
									fillColor:uint=0x990000,fillAlpha:Number=1) 
		{
			_width = width;
			_height = height;
			_fillType = fillType;
			_barColor = barColor;
			_barAlpha = barAlpha;
			_lineColor = lineColor;
			_lineAlpha = lineAlpha;
			_lineWidth = lineWidth;
			_fillColor = fillColor;
			_fillAlpha = fillAlpha;
			
			
			drawBK();
			drawBar();
		}
		
		/**
		 * 绘制进度条背景
		 */
		private function drawBK()
		{
			_bk = new Shape;
			_bk.graphics.beginFill(_fillColor, _fillAlpha);
			_bk.graphics.lineStyle(_lineWidth, _lineColor, _lineAlpha,true,"none");
			_bk.graphics.drawRect(0, 0, _width, _height);
			_bk.graphics.endFill();
			addChild(_bk);
		}
		
		/**
		 * 绘制进度条
		 */
		private function drawBar()
		{
			_bar = new Shape;
			_bar.graphics.beginFill(_barColor, _barAlpha);
			_bar.graphics.lineStyle(_lineWidth, _lineColor, _lineAlpha,true,"none");
			_bar.graphics.drawRect(0, 0, _width, _height);
			_bar.graphics.endFill();
			addChild(_bar);
		}
		
		/**
		 * 设置进度条的进度
		 * @param	current
		 * @param	max
		 */
		public function setScale(current:Number, max:Number)
		{
			_current = current;
			_max = max;
			if (_current < 0) _current = 0;
			if (_current > _max) _current = _max;
			var scale:Number = _current / _max;
			_bar.scaleX = scale;
		}
		
		/**
		 * 设置最大值
		 * @param	max
		 * @param	reset	是否重新设置当前值和最大值
		 */
		public function setMax(max:Number,reset:Boolean=false)
		{
			if (reset)
			{
				setScale(max, max);
			}
			else
			{
				setScale(_current, max);
			}
		}
		
		/**
		 * 设置当前值
		 * @param	current
		 * @param	reset	是否重新设置当前值和最大值
		 */
		public function setCurrent(current:Number, reset:Boolean = false)
		{
			if (reset)
			{
				setScale(current, current);
			}
			else
			{
				setScale(current, _max);
			}
		}
		
		/**
		 * 获取最大值
		 * @return
		 */
		public function getMax():Number
		{
			return _max;
		}
		
		/**
		 * 获取当前值
		 * @return
		 */
		public function getCurrent():Number
		{
			return _current;
		}
		
	}

}