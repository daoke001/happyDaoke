package com.iflashigame.utils 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	/**
	 * ...
	 * @author faster
	 */
	public class YanzhengmaBitmap extends Sprite
	{
		private var num:int;
		private var arr:Array = ["0","1","2","3","4","5","6","7","8","9"];
		private var color:Array;		//随机颜色
		private var font:Array;			//随机字体
		private var vColor:Array;		//随机早点颜色
		private var w:int;
		private var h:int;
		private var r:int = 15;
		
		private var fontLayer:Sprite;
		private var bkLayer:Bitmap;
		private var tempStr:String;
		
		public function YanzhengmaBitmap(w:Number,h:Number) 
		{
			init();
			num = 4;
			this.w = w;
			this.h = h;
		}
		private function init():void
		{
			//生成字体颜色数组
			color = new Array();
			color.push(0x000000);
			color.push(0x000066);
			color.push(0x330000);
			color.push(0x00002F);
			//生成字体数组;
			font = new Array();
			font.push("黑体");
			font.push("Comic Sans MS");
			font.push("Arial");
			font.push("Symbol");
			//生成燥声点的颜色数组;
			vColor = new Array();
			vColor.push(0xFF99FF);
			vColor.push(0xFFCCFF);
			vColor.push(0xFFCC99);
			vColor.push(0x9999FF);
		}

		public function create()
		{
			if (bkLayer != null)
			{
				removeChild(bkLayer);
				bkLayer = null;
			}
			bkLayer = makeV(w, h);
			bkLayer.alpha = 0.8
			addChild(bkLayer);

			if (fontLayer != null)
			{
				removeChild(fontLayer);
				fontLayer = null;
			}
			fontLayer = makeFont();
			fontLayer.alpha = 0.6;
			addChild(fontLayer);
		}
		
		public function getValue():String
		{
			return tempStr;
		}
		
		//生成随机点燥声
		private function makeV(w:int, h:int):Bitmap
		{
			var bit:BitmapData = new BitmapData(w,h);
			var px:int;
			var py:int;
			var c:uint;
			for (var i:int = 0; i < 10000; i++)
			{
				py = Math.random() * h;
				px = Math.random() * w;
				c = Tools.randomFromArr(vColor);
				bit.setPixel(px, py, c);
			}
			return new Bitmap(bit);
		}

		//生成验证码文字
		private function makeFont():Sprite
		{
			tempStr = Tools.randomFromArr(arr) + Tools.randomFromArr(arr) + Tools.randomFromArr(arr) + Tools.randomFromArr(arr);
			trace(tempStr);
			var sprite:Sprite = new Sprite();
			for (var i:int = 0; i < num; i++)
			{
				var temp:TextField = new TextField();
				temp.text = tempStr.charAt(i);
				temp.textColor = uint(Tools.randomFromArr(color));
				var format:TextFormat = new TextFormat();
				format.color = uint(Tools.randomFromArr(color));
				format.font = Tools.randomFromArr(font);
				format.size = 60;
				temp.setTextFormat(format);
				temp.x = 10+i*40;
				temp.y = setRandom(-5,5) + 7;
				temp.selectable = false;
				sprite.addChild(temp);
			}
			
			return sprite;
		}

		private function setRandom(b:Number,e:Number):Number
		{
			var result:Number;
			result = Math.random() * (e - b);
			result +=  b;
			return result;
		}
	}
}