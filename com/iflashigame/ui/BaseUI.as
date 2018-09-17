package com.iflashigame.ui 
{
	import com.greensock.TweenLite;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.system.ApplicationDomain;
	
	/**
	 * UI框架所使用的基类。适合于搭建任意UI
	 * @author 闪刀浪子
	 */
	public class BaseUI extends Sprite 
	{
		protected var _skin: MovieClip;		//皮肤
		private var _maskColor:uint;
		private var _maskAlpha:Number = 1;
	    /**
		 * 构造函数
		 * 
		 * @param code
		 * @param appDomain
		 */
	    public function BaseUI(code:String, appDomain:ApplicationDomain=null)
	    {
			if (code == null) return;
			init(code, appDomain);
	    }

	    /**
		 * 界面初始化函数
		 * 
		 * @param code
		 * @param appDomain
		 */
	    public function init(code:String, appDomain:ApplicationDomain): void
	    {
			if (appDomain == null)	appDomain = ApplicationDomain.currentDomain;
			initSkin(code, appDomain);
			initView();
			initEvent();
	    }

	    /**
		 * 创建UI皮肤
		 * 
		 * @param code
		 * @param appDomain
		 */
	    protected function initSkin(code:String, appDomain:ApplicationDomain = null): void
	    {
			var skinClass:Class = appDomain.getDefinition(code) as Class;
			_skin = (new skinClass()) as MovieClip;
			addChild(_skin);
		}

		/**
		 * 将皮肤元件与变量名绑定
		 */
	    protected function initView(): void
	    {
			
	    }

		/**
		 * 初始化事件
		 */
	    protected function initEvent(): void
	    {
			
	    }

		/**
		 * 设置界面显示所需要的数据
		 * 
		 * @param data
		 */
		public function initData(data:Object): void
		{
			
		}
		
		/**
		 * 创建一个背景遮罩
		 * 
		 * @param x
		 * @param y
		 * @param width
		 * @param height
		 * @param color
		 * @param alpha
		 */
		public function createMask(color:uint, alpha:Number): void
		{
			_maskColor = color;
			_maskAlpha = alpha;
			if (stage == null) 
			{
				addEventListener(Event.ADDED_TO_STAGE,createMaskHandler)
				return;
			}
			createMaskHandler(null);
		}
		
		private function createMaskHandler(evt:Event)
		{
			graphics.clear();
			var topLeftPoint:Point = globalToLocal(new Point());
			graphics.beginFill(_maskColor, _maskAlpha);
			graphics.drawRect(topLeftPoint.x, topLeftPoint.y, stage.stageWidth, stage.stageHeight);
			graphics.endFill();
		}
		
		/**
		 * 移除遮罩
		 */
		public function removeMask(): void
		{
			graphics.clear();
		}	
		
		/**
		 * 从当前状态缩放到新的状态
		 * @param	scaleX
		 * @param	scaleY
		 * @param	alpha
		 * @param	during	动画执行的时间
		 * @param	fun		动画执行结束后的动画
		 */
		public function zoomTo(endScaleX:Number,endScaleY:Number,endAlpha:Number=1,during:Number=1,fun:Function=null)
		{
			if (fun != null)
				TweenLite.to(this, during, 
							{ scaleX:endScaleX, scaleY:endScaleY, alpha:endAlpha, onComplete:fun } );
			else
				TweenLite.to(this, during,
							{ scaleX:endScaleX, scaleY:endScaleY, alpha:endAlpha } );
		}
		
		/**
		 * 从某个状态缩放到现在的状态
		 * @param	scaleX
		 * @param	scaleY
		 * @param	alpha
		 * @param	during	动画执行的时间
		 * @param	fun		动画执行结束后的动画
		 */
		public function zoomFrom(startScaleX:Number,startScaleY:Number,startAlpha:Number=1,during:Number=1,fun:Function=null)
		{
			if (fun != null)
				TweenLite.from(this, during, 
							{ scaleX:startScaleX, scaleY:startScaleY, alpha:startAlpha, onComplete:fun } );
			else
				TweenLite.from(this, during,
							{ scaleX:startScaleX, scaleY:startScaleY, alpha:startAlpha } );
		}
		
		/**
		 * 滑动到新的状态
		 */
		public function rollTo(endX:Number,endY:Number,endAlpha:Number=1,during:Number=1,fun:Function=null)
		{
			if (fun != null)
				TweenLite.to(this, during,
							{x:endX, y:endY, alpha:endAlpha, onComplete:fun } );
			else
				TweenLite.to(this, during,
							{x:endX, y:endY, alpha:endAlpha } );
		}
		
		/**
		 * 从某个状态滑动到新状态
		 */
		public function rollFrom(startX:Number, startY:Number, startAlpha:Number = 1, during:Number = 1, fun:Function = null)
		{
			if (fun != null)
				TweenLite.to(this, during,
							{x:startX, y:startY, alpha:startAlpha, onComplete:fun } );
			else
				TweenLite.to(this, during,
							{x:startX, y:startY, alpha:startAlpha } );
		}
		
		public function getSkin():MovieClip
		{
			return _skin;
		}
	}
}