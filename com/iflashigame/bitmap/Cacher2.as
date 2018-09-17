package com.iflashigame.bitmap 
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	/**
	 * 位图缓存工具类
	 * @author Faster
	 * 负责将矢量动画缓存为位图方式
	 */
	public class Cacher2 extends EventDispatcher
	{
		public var bitmapSpriteInfo:BitmapSpriteInfo;
		public var transparent:Boolean;
		public var fillColor:uint;
		public var scale:Number;
		public var started:Boolean;
		public var name:String;
		/**
		 * 缓存单张位图
		 * @param	source			要被绘制的目标对象
		 * @param	transparent	是否透明
		 * @param	fillColor			填充色
		 * @param	scale				绘制的缩放值
		 * @return  {x,y,bitmapData}
		 */
		public function cacheBitmap(source:DisplayObject, transparent:Boolean = true, fillColor:uint = 0x00000000, scale:Number = 1):Object
		{
			var rect:Rectangle = source.getBounds(source);
			var x:int = Math.round(rect.x * scale);
			var y:int = Math.round(rect.y * scale);
			
			//防止 "无效的 BitmapData"异常
			if (rect.isEmpty())
			{
				rect.width = 1;
				rect.height = 1;
				return {x:x,y:y,bitmapData:new BitmapData(1,1,true,0)}
			}
			
			var bitData:BitmapData = new BitmapData(Math.ceil(rect.width * scale), Math.ceil(rect.height * scale), transparent, fillColor);
			bitData.draw(source, new Matrix(scale, 0, 0, scale, -x, -y), null, null, null, true);
			
			//剔除边缘空白像素
			var realRect:Rectangle = bitData.getColorBoundsRect(0xFF000000, 0x00000000, false);
			
			if (!realRect.isEmpty() && (bitData.width != realRect.width || bitData.height != realRect.height))
			{
				
				var realBitData:BitmapData = new BitmapData(realRect.width, realRect.height, transparent, fillColor);
				realBitData.copyPixels(bitData, realRect, new Point);
				
				bitData.dispose();
				bitData = realBitData;
				x += realRect.x;
				y += realRect.y;
				
			}
			
			var bitInfo:Object = { };
			bitInfo.x = x;
			bitInfo.y = y;
			bitInfo.bitmapData = bitData;
			
			return bitInfo;
		}
		
		/**
		 * 缓存位图动画
		 * @param	mc				要被绘制的影片剪辑
		 * @param	transparent	是否透明
		 * @param	fillColor			填充色
		 * @param	scale				绘制的缩放值
		 * @return
		 */
		public function cacheBitmapMovie(source:DisplayObject, transparent:Boolean = true, fillColor:uint = 0x00000000, 
												scale:Number = 1)
		{
			this.transparent = transparent;
			this.fillColor = fillColor;
			this.scale = scale;
			var mc:MovieClip = source as MovieClip;
			var obj:Object;
			if (mc == null)
			{
				
				bitmapSpriteInfo = new BitmapSpriteInfo(1);
				obj = cacheBitmap(source, transparent, fillColor, scale);
				
				var singleInfo:BitmapSpriteFrameInfo = new BitmapSpriteFrameInfo(obj.bitmapData, obj.x, obj.y);
				bitmapSpriteInfo.addAt(0, singleInfo);
				dispatchEvent(new Event(Event.COMPLETE));
			}
			else
			{
				var i:int = 0;
				var c:int = mc.totalFrames;
				
				//trace("动画帧数为：", c);
				mc.gotoAndStop(1);
				bitmapSpriteInfo = new BitmapSpriteInfo(c);
				
				//攻击点信息
				var hitPoint:MovieClip = mc.getChildByName("_hitPoint") as MovieClip;
				if(hitPoint!=null)
				bitmapSpriteInfo.hitPoint=new Point(hitPoint.x * scale, hitPoint.y * scale);
				
				mc.addEventListener(Event.ENTER_FRAME, onEnterframeHandler);
			}
		}
		
		private function onCompleteHandler(evt:Event):void 
		{
			trace("complete");
		}
		
		private function onEnterframeHandler(evt:Event)
		{
			var mc:MovieClip = evt.currentTarget as MovieClip;
			//防止跳过第一帧执行
			if (started == false)
			{
				started = true;
				mc.gotoAndPlay(1);
				//return;
			}
			var i:int = mc.currentFrame-1;
			var c:int = mc.totalFrames;
			//trace("第", mc.currentFrame, "帧的信息");
			var obj:Object = cacheBitmap(mc, transparent, fillColor, scale);
			
			//如果得到的位图与上一帧相同则使用上一帧的位图
			//if (i != 0 && bitmapSpriteInfo.getAt(i - 1).data.compare(obj.bitmapData) == 0)
			//{
				//obj.bitmapData = bitmapSpriteInfo.getAt(i - 1).data;
			//}
			var frameInfo:BitmapSpriteFrameInfo = new BitmapSpriteFrameInfo(obj.bitmapData, obj.x, obj.y);
			//正常的是一个循环
			frameInfo.next = i + 1 == c?1:i + 1;
			
			//trace("准备标签分析...");
			//分析标签和脚本
			if (mc.currentFrameLabel != null) 
			{
				var labelStr:String = mc.currentFrameLabel;
				frameInfo.label = labelStr.split("|")[0];
				
				var codeStr:String = labelStr.split("|")[1];
				if (codeStr != null)
				{
					var codeArr:Array = codeStr.split(";");
					for (var j:int = 0; j < codeArr.length; j++)
					{
						if (codeArr[j] == "stop()")
						{
							frameInfo.next = -1;
						}
						else if (codeArr[j].indexOf("gotoAndStop(\"") != -1)
						{
							var gstop1:String = codeArr[j].match(/"\S+"/)[0];
							var slabel:String=gstop1.substring(1, gstop1.length - 1);
							frameInfo.next=bitmapSpriteInfo.findLabel(slabel);
						}
						else if (codeArr[j].indexOf("gotoAndStop(") != -1)
						{
							var gstop2:String = codeArr[j].match(/\(\d+\)/)[0];
							frameInfo.next=int(gstop2.substring(1,gstop2.length-1));
						}
						else if (codeArr[j].indexOf("gotoAndPlay(\"") != -1)
						{
							var gplay1:String = codeArr[j].match(/"\S+"/)[0];
							var glabel:String = gplay1.substring(1, gplay1.length - 1);
							frameInfo.next=bitmapSpriteInfo.findLabel(glabel);
						}
						else if (codeArr[j].indexOf("gotoAndPlay(") != -1)
						{
							var gplay2:String = codeArr[j].match(/\(\d+\)/)[0];
							frameInfo.next=int(gplay2.substring(1,gplay2.length-1));
						}
						else if (codeArr[j].indexOf("Event=") != -1)
						{
							var gevent:String = codeArr[j].match(/"\S+"/)[0];
							frameInfo.event= gevent.substring(1, gevent.length - 1);									
						}
					}
				}
			}
			bitmapSpriteInfo.addAt(i, frameInfo);
			//trace(evt.currentTarget.currentFrame, evt.currentTarget.totalFrames);
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS));
			if (evt.currentTarget.currentFrame == evt.currentTarget.totalFrames)
			{
				evt.currentTarget.removeEventListener(Event.ENTER_FRAME, onEnterframeHandler);
				started = false;
				for (var n:int = 1; n < bitmapSpriteInfo.frameCount; n++)
				{
					var pre:BitmapSpriteFrameInfo = bitmapSpriteInfo.getAt(n - 1);
					var curr:BitmapSpriteFrameInfo = bitmapSpriteInfo.getAt(n);
					//比较位图是否相同
					if (pre.data.compare(curr.data) == 0)
					{
						curr.data = pre.data;	//替换位图元素
						curr.delay = 0;
						var m:int = 1;
						while (bitmapSpriteInfo.getAt(n - m).delay == 0)
						{
							m++;
						}
						bitmapSpriteInfo.getAt(n - m).delay++;
					}
				}
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		/**
		 * 将精灵位图信息转换为二进制数组用于保存
		 * @param	data
		 * @return
		 */
		public static function coverBin(b:BitmapSpriteInfo):ByteArray
		{
			var byteArray:ByteArray = new ByteArray;
			byteArray.writeFloat(b.hitPoint.x);		//记录攻击点
			byteArray.writeFloat(b.hitPoint.y);
			byteArray.writeInt(b.frameCount);		//记录总帧数
			for (var i:int = 0; i < b.frameCount; i++)
			{
				var frame:BitmapSpriteFrameInfo = b.getAt(i);
				byteArray.writeFloat(frame.x);		//坐标偏移量
				byteArray.writeFloat(frame.y);
				byteArray.writeInt(frame.next);		//下一帧
				byteArray.writeUTF(frame.label);	//帧标签
				byteArray.writeUTF(frame.event);	//事件
				byteArray.writeInt(frame.delay);	//占用帧数
				if (frame.delay != 0)				//位图信息
				{
					byteArray.writeFloat(frame.data.width);
					byteArray.writeFloat(frame.data.height);
					var bitArr:ByteArray = frame.data.getPixels(frame.data.rect);
					byteArray.writeObject(bitArr);		//位图数据
				}
			}
			byteArray.compress();
			return byteArray;
		}
		
		/**
		 * 将二进制数组还原为精灵位图对象
		 * @param	b
		 * @return
		 */
		public static function revertBin(b:ByteArray):BitmapSpriteInfo
		{
			b.uncompress();
			b.position = 0;
			var hitX:Number = b.readFloat();
			var hitY:Number = b.readFloat();
			var frameCount:int = b.readInt();
			var data:BitmapSpriteInfo = new BitmapSpriteInfo(frameCount);
			data.hitPoint = new Point(hitX, hitY);
			for (var i:int = 0; i < frameCount; i++)
			{
				var frameInfo:BitmapSpriteFrameInfo = new BitmapSpriteFrameInfo();
				frameInfo.x = b.readFloat();
				frameInfo.y = b.readFloat();
				frameInfo.next = b.readInt();
				frameInfo.label = b.readUTF();
				frameInfo.event = b.readUTF();
				frameInfo.delay = b.readInt();
				if (frameInfo.delay == 0)
				{
					frameInfo.data = data.getAt(i - 1).data;
				}
				else
				{
					var bitmapData:BitmapData = new BitmapData(b.readFloat(), b.readFloat());
					bitmapData.setPixels(bitmapData.rect,ByteArray(b.readObject()));
					frameInfo.data = bitmapData;
				}
				data.addAt(i, frameInfo);
			}
			trace("asdasdfadsf");
			return data;
		}
	}
}