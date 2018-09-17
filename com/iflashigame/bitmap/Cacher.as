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
	public class Cacher extends EventDispatcher
	{
		public var bitmapSpriteInfo:BitmapSpriteInfo;
		public var transparent:Boolean;
		public var fillColor:uint;
		public var scale:Number;
		public var started:Boolean;
		public var name:String;
		
		private var _frames:Vector.<int>	//已经渲染的帧，用于跳过stop等代码
		private var _stage:Stage;	//stage的引用
		private var _rate:int;		//保存stage的初始帧频
		private var _aniInfo:String;	//mc的动画信息
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
			
			//防止 "无效的 BitmapData"异常
			if (rect.isEmpty())
			{
				rect.width = 1;
				rect.height = 1;
				return {x:0,y:0,bitmapData:new BitmapData(1,1,true,0)}
			}
			rect.inflate(20, 20);
			var x:int = Math.round(rect.x * scale);
			var y:int = Math.round(rect.y * scale);
			
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
		 * 缓存MovieClip动画
		 * @param	stage	主场景
		 * @param	source	需要缓存的MC
		 * @param	aniInfo	MC对应的动画信息
		 * @param	transparent
		 * @param	fillColor
		 * @param	scale
		 */
		public function cacheBitmapMovie(stage:Stage,source:DisplayObject, aniInfo:String,transparent:Boolean = true, fillColor:uint = 0x00000000, 
												scale:Number = 1)
		{
			this._stage = stage;
			this._rate = stage.frameRate;
			this._aniInfo = aniInfo;
			
			this.transparent = transparent;
			this.fillColor = fillColor;
			this.scale = scale<=0?0.01:scale;
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
				
				trace("动画帧数为：", c);
				mc.gotoAndStop(1);
				bitmapSpriteInfo = new BitmapSpriteInfo(c);
				
				//攻击点信息
				var hitPoint:MovieClip = mc.getChildByName("_hitPoint") as MovieClip;
				if(hitPoint!=null)
				bitmapSpriteInfo.hitPoint=new Point(hitPoint.x * scale, hitPoint.y * scale);
				_frames = new Vector.<int>;
				stage.frameRate = 60;
				
				//addEventListener("rendComplete", onRenderCompleteHandler);
				mc.addEventListener(Event.ENTER_FRAME, onEnterframeHandler);
			}
		}
		
		private function onEnterframeHandler(evt:Event)
		{
			var mc:MovieClip = evt.currentTarget as MovieClip;
			//防止跳过第一帧执行
			if (started == false)
			{
				started = true;
				mc.gotoAndPlay(1);
			}
			//解决stop或者向前跳转的情况
			if (_frames.indexOf(mc.currentFrame)!=-1)
			{
				mc.gotoAndPlay(_frames.length + 1);
			}
			//解决像后跳转的情况
			if (mc.currentFrame-_frames.length>1)
			{
				mc.gotoAndPlay(_frames.length + 1);
			}
			var i:int = mc.currentFrame-1;
			var c:int = mc.totalFrames;
			var obj:Object = cacheBitmap(mc, transparent, fillColor, scale);
			
			var frameInfo:BitmapSpriteFrameInfo = new BitmapSpriteFrameInfo(obj.bitmapData, obj.x, obj.y);
			//正常的是一个循环
			frameInfo.next = i + 1 == c?0:i + 1;	//从0开始
			
			//分析标签和脚本
			if (mc.currentFrameLabel != null) 
			{
				frameInfo.label = mc.currentFrameLabel;
			}
			bitmapSpriteInfo.addAt(i, frameInfo);
			
			//trace("当前第", mc.currentFrame, "帧");
			if(_frames.indexOf(mc.currentFrame)==-1)
			_frames.push(mc.currentFrame);
			
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS,false,false,i+1,c));
			if (_frames.length == mc.totalFrames)
			{
				trace("完成预渲染");
				evt.currentTarget.removeEventListener(Event.ENTER_FRAME, onEnterframeHandler);
				started = false;
				/**
				 * 查找前后帧相同的情况，如果相同，位图信息用前一帧的替代
				 */
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
				onRenderComplete()
			}
		}
		
		/**
		 * 渲染完成准备添加控制代码和事件
		 * @param	evt
		 */
		private function onRenderComplete():void 
		{
			//注意判断如果_aniInfo没有的情况(主时间轴)
			_stage.frameRate = _rate;
			if (_aniInfo != null)
			{
				//trace(_aniInfo);
				//获取实例的前缀名
				var lineArr:Array = _aniInfo.split("\n");
				var nameArr:Array = lineArr[0].split("::");
				var prefix:String = nameArr.length == 2?nameArr[0] + "::":"";
				//trace("prefix=", prefix);
				
				//分析addFrameScript代码
				var addFrameArr:Array = _aniInfo.match(/addFrameScript(\S|\s)+addFrameScript/g);
				//trace("addFrameArr=", addFrameArr);
				if (addFrameArr != null && addFrameArr.length > 0)
				{
					var head:String = addFrameArr[0];
					var reg:RegExp = new RegExp(prefix + "frame\\d+", "g");
					var funNameArr:Array = head.match(reg);
					//trace("funNameArr=",funNameArr);
					
					//逐个分析帧代码
					for (var i:int = 0; i < funNameArr.length; i++)
					{
						var funReg:RegExp = new RegExp("function " + funNameArr[i] + "(\\S|\\s)[^}]+}", "g");
						var funcodeArr:Array = _aniInfo.match(funReg);
						//trace("funcodeArr=", funcodeArr);
						
						if (funcodeArr != null && funcodeArr.length > 0)
						{
							setFrameInfo(prefix,funcodeArr[0]);
						}
					}
				}
			}
			dispatchEvent(new Event(Event.COMPLETE));
			trace("缓存完毕");
		}
		
		/**
		 * 将帧控制信息写入位图对象
		 * @param	str
		 */
		private function setFrameInfo(prefix:String,str:String)
		{
			//trace("frameInfo=",str);
			var strArr:Array = str.split("\n");
			var head:String = strArr[0];
			
			var a:String = "function " + prefix + "frame";
			var b:int = head.indexOf("()");
			var frame:int = int(head.substring(a.length, b));
			//trace("找到了帧", frame);
			var frameInfo:BitmapSpriteFrameInfo = bitmapSpriteInfo.getAt(frame-1);
			
			for (var i:int = 1; i < strArr.length; i++)
			{
				var nextStr:String;
				var index:int;
				if (strArr[i].indexOf("findpropstrict	gotoAndPlay") != -1||strArr[i].indexOf("findpropstrict	gotoAndStop") != -1)
				{
					nextStr = strArr[i + 1];
					index=nextStr.indexOf("pushbyte      	")
					if (index != -1)
					{
						index = int(nextStr.split("pushbyte      	")[1]);
						index = index > bitmapSpriteInfo.frameCount?bitmapSpriteInfo.frameCount:index;
						index = index < 1?1:index;
						frameInfo.next = index - 1;		//帧在事件轴上是从1开始算的
						i++;
					}
					index=nextStr.indexOf("pushstring    	")
					if ( index!= -1)
					{
						var label:String = nextStr.split("pushstring    	")[1];
						label = label.substr(1, label.length - 2);
						index = bitmapSpriteInfo.findLabel(label);
						if (index != -1)
						frameInfo.next = index;		//内部找到的从0开始算，不用-1
						i++;
					}
				}
				else if (strArr[i].indexOf("findpropstrict	stop") != -1)
				{
					frameInfo.next = -1;
				}
				else if (strArr[i].indexOf("findpropstrict	flash.events::Event") != -1)
				{
					nextStr = strArr[i + 1];
					if (nextStr.indexOf("pushstring    	") != -1)
					{
						var event:String = nextStr.split("pushstring    	")[1];
						event = event.substr(1, event.length - 2);
						
						var bubble:Boolean = false;
						var third:String = strArr[i + 2];
						if (third.indexOf("pushtrue      	") != -1)
						{
							bubble = true;
							i = i + 2;
						}
						else
						{
							bubble = false;
							i = i + 1;
						}
						frameInfo.addEvent(event, bubble);
					}
				}
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
				byteArray.writeInt(frame.totalEvents);	//记录事件数量
				for (var j:int = 0; j < frame.totalEvents; j++)
				{
					var obj:Object = frame.getEvent(j);
					byteArray.writeUTF(obj.event);
					byteArray.writeBoolean(obj.bubbles);
				}
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
				var totalEvents:int = b.readInt();		//事件数量
				for (var j:int = 0; j < totalEvents; j++)
				{
					frameInfo.addEvent(b.readUTF(),b.readBoolean());
				}
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
			return data;
		}
	}
}