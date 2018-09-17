package com.iflashigame.utils 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.SimpleButton;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.ApplicationDomain;
	/**
	 * 工具类
	 * @author faster
	 */
	public class Tools
	{
		public static function setGray(mc:InteractiveObject,val:Boolean)
		{
			if (val)
			{
				var matrix:Array = new Array();
				matrix = matrix.concat([0.3086,0.6094,0.082,0,0]); // red
				matrix = matrix.concat([0.3086,0.6094,0.082,0,0]); // green
				matrix = matrix.concat([0.3086,0.6094,0.082,0,0]); // blue
				matrix = matrix.concat([0, 0, 0, 1, 0]); // alpha
				var filter:ColorMatrixFilter = new ColorMatrixFilter(matrix);
				var filters:Array = new Array();
				filters.push(filter);
				mc.filters = filters;
			}
			else
			{
				mc.filters = [];
			}
		}
		
		/**
		 * 使交互的可视对象失效并显示为灰色
		 * @param	mc	需要变灰色的图标
		 * @param	disabled	
		 * @param	gray	是否需要变灰
		 */
		public static  function setDisabled(mc:InteractiveObject, disabled:Boolean, gray:Boolean = true )
		{
			if(gray)
			setGray(mc, disabled);
			
			if(disabled){
				if (mc is SimpleButton)
				{
					(mc as SimpleButton).enabled = false;
					mc.mouseEnabled = false;
				}
				else
				{
					mc.mouseEnabled = false;
					if (mc is DisplayObjectContainer)
					{
						(mc as DisplayObjectContainer).mouseChildren = false;
					}
				}
			}
			else 
			{
				if (mc is SimpleButton)
				{
					(mc as SimpleButton).enabled = true;
					mc.mouseEnabled = true;
				}
				else
				{
					mc.mouseEnabled = true;
					if (mc is DisplayObjectContainer)
					{
						(mc as DisplayObjectContainer).mouseChildren = true;
					}
				}
			}
		}

		/**
		 * 从数组中随机挑出一个数据
		 * @return
		 */
		public static function randomFromArr(arr:Array,len:int=-1):*
		{
			var length:int 
			if (len == -1)
			length = arr.length;
			else
			length = arr.length > len?len:arr.length;
			var index:int = Math.floor(length * Math.random());
			return arr[index];
		}
		
		/**
		 * 清空容器
		 * @param	container
		 */
		public static function clearContainer(container:DisplayObjectContainer)
		{
			while (container.numChildren > 0)
			{
				container.removeChildAt(0);
			}
		}
		
		
		/**
		 * 设置显示对象的亮度 
		 * @param	obj		需要设置的对象
		 * @param	bright	亮度  0-1;
		 */
		public static function setBright(obj:DisplayObject, bright:Number)
		{
			if (obj == null) return;
			
			if (bright < 0) bright = 0;
			else if (bright > 1) bright = 1;
			
			var colorTransform:ColorTransform = obj.transform.colorTransform;
			var offset:int = Math.round(255 * bright);
			colorTransform.redMultiplier = 1 - bright;
			colorTransform.greenMultiplier = 1 - bright;
			colorTransform.blueMultiplier = 1 - bright;
			colorTransform.redOffset = offset;
			colorTransform.greenOffset = offset;
			colorTransform.blueOffset = offset;
			obj.transform.colorTransform = colorTransform;
		}
		
		public static function ChangeColor(select:DisplayObject,red:Number,green:Number,blue:Number)
		{
			var resultColorTransform:ColorTransform = new ColorTransform();
			resultColorTransform.redOffset = red;
			resultColorTransform.blueOffset = green;
			resultColorTransform.greenOffset = blue;
			select.transform.colorTransform = resultColorTransform;
		}
		
		/**
		 * 选择地图物品
		 * @param	contain		地图层的引用
		 * @param	stagePoint
		 * @param	exclude		图标层的引用
		 * @return
		 */
		public static function selectObject (contain:DisplayObjectContainer,stagePoint:Point,myClass:Class):*
		{
			if (contain == null)
			return null;
			var arr=contain.stage.getObjectsUnderPoint(stagePoint);//取得容器中鼠标处的对象数组
			if(arr.length==0)
				return null;
				
			var rec:Rectangle = new Rectangle(0, 0, 1, 1); //定义一个1像素的矩形
			var matrix:Matrix = new Matrix();
			for (var i = arr.length - 1; i >= 0; i--)//从上至下比较
			{
				var bitmapData:BitmapData = new BitmapData(1, 1,true,0);
				var point:Point = (arr[i] as DisplayObject).globalToLocal(stagePoint);
				matrix.tx = -int(point.x); //将鼠标点移动到左上角
				matrix.ty = -int(point.y);
				if(contain.contains(arr[i] as DisplayObject))//选择的物体必须包含在制定容器中。
				{
					bitmapData.draw(arr[i], matrix, null, null, rec);//复制一个像素
					var pixelVal:uint = bitmapData.getPixel32(0, 0);
					var alphaVal:uint = pixelVal >> 24 & 0xFF;
					if (alphaVal!=0x81&&pixelVal!=0)//如果不是透明的则表示这个对象是你选择的。
					{
						bitmapData.dispose ();//清空位图
						if (arr[i] is myClass) return arr[i] as myClass;
						while (arr[i]!= contain)
						{
							arr[i] = arr[i].parent;
							if (arr[i] is myClass) 
							{
								return arr[i] as myClass;
							}
						}
						//return null;
					}
				}
				else
				{
					return null;
				}
			}
			return null;
		}
		
		/**
		 * 根据给定的几率计算是否触发
		 * @param	jilv	几率  小数
		 * @param	beishu	几率的倍数 百分之几或者千分之几
		 * @return
		 */
		public static function getJilv(jilv:Number, beishu:int = 100):Boolean
		{
			if (jilv == 1) return true;
			else if (jilv == 0) return false;
			
			var arr:Vector.<Boolean> = new Vector.<Boolean>(beishu, true)
			
			//几率超过50%
			if (jilv > 0.5)
			{
				jilv=1-jilv
				for (var i:int = 0; i < beishu; i++)
				{
					arr[i] = true;
				}
				
				var length:int = int(jilv * beishu);
				var j:int = 0;
				while (j < length)
				{
					var pos:int = int(Math.random() * beishu);
					if (arr[pos] == true)
					{
						arr[pos] = false;
						j++;
					}
				}
			}
			else
			{
				for (var k:int = 0; k < beishu; k++)
				{
					arr[k] = false;
				}
				
				var length2:int = int(jilv * beishu);
				var m:int = 0;
				while (m < length2)
				{
					var pos2:int = int(Math.random() * beishu);
					if (arr[pos2] == false)
					{
						arr[pos2] = true;
						m++;
					}
				}
			}
			return arr[int(Math.random() * beishu)];
		}
		
		/**
		 * 从一个数组中删除另一个数组中指定的字符串
		 * @param	container
		 * @param	sub
		 * @return
		 */
		public static function removeArrFromArr(container:Vector.<String>, sub:Vector.<String>):Array
		{
			var obj:Object = { };
			for (var i:int = 0; i < container.length; i++)
			{
				obj[container[i]] = container[i];
			}
			
			for (var j:int = 0; j < sub.length; j++)
			{
				delete obj[sub[j]];
			}
			
			var arr:Array = [];
			for (var k in obj)
			{
				arr.push(obj[k]);
			}
			
			return arr;
		}
		
		/**
		 * 根据编码创建可是对象
		 * @param	code
		 * @return
		 */
		public static function createDisplayObject(code:String,appDomain:ApplicationDomain=null):DisplayObject
		{
			if (appDomain == null) appDomain = ApplicationDomain.currentDomain;
			var skinClass:Class = appDomain.getDefinition(code) as Class;
			var disp:*= new skinClass;
			if (disp is BitmapData)
			return new Bitmap(disp as BitmapData);
			else
			return new disp as DisplayObject;
		}
	}

}