package com.iflashigame.bitmap 
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * 位图缓存工具类
	 * @author Faster
	 * 负责将矢量动画缓存为位图方式
	 */
	public class BitmapCacher
	{
		
		/**
		 * 缓存单张位图
		 * @param	source			要被绘制的目标对象
		 * @param	transparent	是否透明
		 * @param	fillColor			填充色
		 * @param	scale				绘制的缩放值
		 * @return  {x,y,bitmapData}
		 */
		static public function cacheBitmap(source:DisplayObject, transparent:Boolean = true, fillColor:uint = 0x00000000, scale:Number = 1):Object
		{
			
			var rect:Rectangle = source.getBounds(source);
			rect.inflate(20, 20);
			var x:int = Math.round(rect.x * scale);
			var y:int = Math.round(rect.y * scale);
			
			//防止 "无效的 BitmapData"异常
			if (rect.isEmpty())
			{
				rect.width = 1;
				rect.height = 1;
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
		static public function cacheBitmapMovie(source:DisplayObject, transparent:Boolean = true, fillColor:uint = 0x00000000, 
												scale:Number = 1):BitmapSpriteInfo
		{
			var bitmapSpriteInfo:BitmapSpriteInfo;
			var mc:MovieClip = source as MovieClip;
			var obj:Object;
			if (mc == null)
			{
				
				bitmapSpriteInfo = new BitmapSpriteInfo(1);
				obj = cacheBitmap(source, transparent, fillColor, scale);
				
				var singleInfo:BitmapSpriteFrameInfo = new BitmapSpriteFrameInfo(obj.bitmapData, obj.x, obj.y);
				bitmapSpriteInfo.addAt(0, singleInfo);
				
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
				
				while (i < c)
				{
					//trace("第",i+1,"帧的信息");
					obj = cacheBitmap(mc, transparent, fillColor, scale);
					
					//如果得到的位图与上一帧相同则使用上一帧的位图
					if (i != 0 && bitmapSpriteInfo.getAt(i - 1).data.compare(obj.bitmapData) == 0)
					{
						obj.bitmapData = bitmapSpriteInfo.getAt(i - 1).data;
					}
					var frameInfo:BitmapSpriteFrameInfo = new BitmapSpriteFrameInfo(obj.bitmapData, obj.x, obj.y);
					frameInfo.next = i + 1 == c?0:i + 1;
					
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
					mc.nextFrame();
					i++;
				}
				
			}
			return bitmapSpriteInfo;
		}
		
	}

}