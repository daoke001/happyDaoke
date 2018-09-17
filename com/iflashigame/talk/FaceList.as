package com.iflashigame.talk 
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.system.ApplicationDomain;
	
	/**
	 * 表情列表类，因为TileList出错所以不得已自己写一个类
	 * @author 资强
	 */
	public class FaceList extends Sprite
	{
		private var _tileWidth:int = 24; //大小
		private var _tileHeight:int = 24;
		private var _columnCount:int = 10; //每行的数量
		private var _border:int = 2;
		
		
		private var _appDomain:ApplicationDomain
		public function FaceList(count:int, appDomain:ApplicationDomain = null) 
		{
			_appDomain = appDomain == null?ApplicationDomain.currentDomain:appDomain;
			initFaceList(count);
		}
		
		private function initFaceList(count:int)
		{
			var allFace:Array = [];
			for (var j = 1; j <= count; j++)
			{
				if (j < 10) allFace.push("face0" + j);
				else allFace.push("face" + j);
			}
			var dp:Array = new Array();
			for(var i=0;i<allFace.length;i++)
			{	
				var linkClass:Class = _appDomain.getDefinition(allFace[i].toString()) as Class;
				var mc:MovieClip=new linkClass() as MovieClip;
				var obj=new Object();
				obj.name = allFace[i];
				obj.source=mc;
				dp.push(obj);
			}
			setDP(dp);
		}
		
		private function setDP(dp:Array)
		{
			var count:int = dp.length;
			if (count > 0)
			{
				for (var i = 1; i <= count; i++)
				{
					var mc:MovieClip = new MovieClip();
					mc.mouseChildren = false;
					mc.graphics.beginFill(0x000000, 0.6);
					mc.graphics.lineStyle(1, 0x000000);
					mc.graphics.drawRect(0, 0, _tileWidth+_border*2, _tileHeight+_border*2);
					mc.graphics.endFill();
					mc.source = dp[i - 1].source;
					mc.source.x = mc.source.y = _border;
					mc.addChild(mc.source);
					mc.index = i;
					mc.name=dp[i - 1].name
					var hang:int = Math.ceil(mc.index / _columnCount);
					var lie:int = i - _columnCount * (hang - 1);
					mc.x = (lie - 1) * (_tileWidth+_border*2);
					mc.y = (hang - 1) * (_tileHeight+_border*2);
					addChild(mc);
					mc.buttonMode = true;
				}
				graphics.beginFill(0xffffff, 0.6);
				graphics.drawRect(0, 0, width, height);
				graphics.endFill();
			}			
		}
	}
}
