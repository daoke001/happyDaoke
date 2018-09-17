package com.iflashigame.talk 
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Rectangle;
	import flash.system.ApplicationDomain;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import game.ui.list.IScrollElement;
	
	/**
	 * 图文显示框
	 * @author faster
	 */
	public class TalkField extends Sprite implements IScrollElement
	{
		private var _tf:TextField;
		private var _tfMask:Sprite;
		private var _faceContainer:Sprite;
		
		private var _maskWidth:Number;
		private var _maskHeight:Number;
		
		private var _textFormat:TextFormat;
		private var _leading:Number
		private var _textColor:uint;
		private var _alpha:Number;
		
		private var _appDomain:ApplicationDomain;
		
		/**
		 * 构造函数
		 * @param	width	图文宽度
		 * @param	height
		 * @param	leading  行间距
		 * @param	appDomain
		 */
		public function TalkField(width:Number, height:Number, appDomain:ApplicationDomain = null,
						leading:Number=2,textColor:uint=0xeeeeee,alpha:Number=0) 
		{
			_maskWidth = width;
			_maskHeight = height;
			_leading = leading;
			_textColor = textColor
			_alpha = alpha;
			_appDomain = appDomain==null?ApplicationDomain.currentDomain:appDomain;
			
			initView()
			initEvent();
		}
		
		private function initView()
		{
			createBK();
			createMask();
			createTF();
			createFaceContainer();
		}
		
		private function initEvent()
		{
			addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheelHandler);
		}
		
		private function onMouseWheelHandler(e:MouseEvent):void 
		{
			maskY -= (e.delta * 4.0);
			dispatchEvent(new Event("scroll"));
		}
		
		private function createBK()
		{
			graphics.beginFill(0, _alpha);
			graphics.drawRect( -5, -2, _maskWidth + 10, _maskHeight + 14);
			graphics.endFill();
		}
		
		private function createMask()
		{
			_tfMask = new Sprite();
			_tfMask.graphics.beginFill(0x000000);
			_tfMask.graphics.drawRect(0, 0, _maskWidth, _maskHeight);
			_tfMask.graphics.endFill();
			addChild(_tfMask);
		}
		
		private function createTF()
		{
			_textFormat = new TextFormat;
			_textFormat.color=_textColor;
			_textFormat.size = 12;
			_textFormat.letterSpacing = 0.75;
			_textFormat.leading = _leading;
			
			_tf = new TextField();
			_tf.textColor = 0xeeeeee;
			_tf.width = _maskWidth;
			_tf.defaultTextFormat = _textFormat;
			_tf.selectable = false;
			_tf.multiline = true;
			_tf.wordWrap = true;
			_tf.autoSize = "left";
			_tf.filters = [new GlowFilter(0x000000, 0.95, 2, 2, 10)];
			_tf.mouseWheelEnabled = false;
			addChild(_tf);
			_tf.mask = _tfMask;
		}
		
		private function createFaceContainer()
		{
			_faceContainer = new Sprite();
			_faceContainer.scrollRect = new Rectangle(0, 0, _maskWidth, _maskHeight);
			addChild(_faceContainer);
		}
		
		private function clearFaceContain()
		{
			while (_faceContainer.numChildren > 0)
			{
				_faceContainer.removeChildAt(0);
			}
		}
		
		/**
		 * 聊天显示框
		 * @param	str 必须为htmlText格式
		 */
		public function setText(str:String)
		{
			_tf.text = "";
			_tf.defaultTextFormat = _textFormat;
			var faceArr:Array = [];
			clearFaceContain();
			
			//保存表情符的编号并替换为空格
			//var face:Array = str.match(/\*[0-9][0-9]/g);
			var face:Array = str.match(/\*(0[1-9]|[1-4][0-9]|5[0-3])/g);
			if (face != null)
			{
				faceArr = faceArr.concat(face);
			}
			//str = str.replace(/\*[0-9][0-9]/g, "<font size='24'>　</font>");
			str = str.replace(/\*(0[1-9]|[1-4][0-9]|5[0-3])/g, "<font size='24'>　</font>");
			_tf.htmlText = str;
			_tf.height;
			
			//记录空格的索引号
			var text:String = _tf.text;
			var indexArr:Array = [];
			for (var index:int = 0; index < text.length; index++)
			{
				if (text.charAt(index) == "　")
				{
					indexArr.push(index);
				}
			}
			_tf.height;
			for (var j = 0; j < indexArr.length; j++)
			{
				var tempPos:Rectangle = _tf.getCharBoundaries(indexArr[j]);
				var linkClass:Class = _appDomain.getDefinition("face" + faceArr[j].substr(1, 2)) as Class;
				if (linkClass != null&&tempPos!=null)
				{
					var mc:MovieClip = new linkClass as MovieClip;
					_faceContainer.addChild(mc);
					mc.x = tempPos.x;
					mc.y = tempPos.y+3;
				}
			}
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		/**
		 * 设置文本
		 * @param	arr 频道数组
		 */
		public function setMultiText(arr:Array)
		{
			if (arr == null) return;
			_tf.text = "";
			_tf.defaultTextFormat = _textFormat;
			var faceArr:Array = [];
			clearFaceContain();
			
			var allStr:String=""
			for (var i = 0; i < arr.length; i++)
			{
				//保存表情符的编号并替换为空格
				var str:String = arr[i];
				//var face:Array = str.match(/\*[0-9][0-9]/g);
				var face:Array = str.match(/\*(0[1-9]|[1-4][0-9]|5[0-3])/g);
				if (face != null)
				{
					faceArr = faceArr.concat(face);
				}
				str = str.replace(/\*(0[1-9]|[1-4][0-9]|5[0-3])/g, "<font size='24'>　</font>");
				allStr += str;
			}
			_tf.htmlText = allStr;
			_tf.height;
			
			//记录空格的索引号
			var text:String = _tf.text;
			var indexArr:Array = [];
			for (var index:int = 0; index < text.length; index++)
			{
				if (text.charAt(index) == "　")
				{
					indexArr.push(index);
				}
			}
			_tf.height;
			for (var j = 0; j < indexArr.length; j++)
			{
				var tempPos:Rectangle = _tf.getCharBoundaries(indexArr[j]);
				var linkClass:Class = _appDomain.getDefinition("face" + faceArr[j].substr(1, 2)) as Class;
				if (linkClass != null&&tempPos!=null)
				{
					var mc:MovieClip = new linkClass as MovieClip;
					_faceContainer.addChild(mc);
					mc.x = tempPos.x;
					mc.y = tempPos.y+3;
				}
			}
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		/* INTERFACE game.ui.list.IScrollElement */
		
		public function get maskX():Number 
		{
			return _faceContainer.scrollRect.x;
		}
		
		public function set maskX(val:Number) 
		{
			var rec:Rectangle = _faceContainer.scrollRect;
			rec.x = val;
			_tf.x = -val;
			_faceContainer.scrollRect = rec;
			
		}
		
		public function get maskY():Number 
		{
			return _faceContainer.scrollRect.y;
		}
		
		public function set maskY(val:Number) 
		{
			var rec:Rectangle = _faceContainer.scrollRect;
			if (val < 0) val = 0;
			else if (val > maxScroll) val = maxScroll;
			_tf.y = -val;
			rec.y = val;
			_faceContainer.scrollRect = rec;
		}
		
		public function get minScroll():Number 
		{
			return 0;
		}
		
		public function get maxScroll():Number 
		{
			if (_tf.height <= _tfMask.height) return 0;
			else return _tf.height - _tfMask.height;
		}
	}

}