package com.iflashigame.bitmap 
{
	import flash.utils.ByteArray;
	/**
	 * 位图数据的全局缓存池
	 * @author Faster
	 * 转成位图的数据保存在这里方便随时调用
	 */
	public class GlobalBitmapData 
	{
		/**
		 * 存储动画的位图信息，key=导出类名
		 */
		public static var data:Object = { };
		
		
		/**
		 * 缓存动画位图数据
		 * @param	key		动画资源的导出类名
		 * @param	value	动画位图数据
		 */
		public static function setData(key:String, value:BitmapSpriteInfo)
		{
			data[key] = value;
		}
		
		/**
		 * 缓存动画位图数据
		 * @param	key		动画资源的导出类名
		 * @param	value	动画位图数据
		 */
		public static function setDataBytes(key:String, value:ByteArray)
		{
			data[key] = value;
		}
		
		/**
		 * 取得动画位图数据
		 * @param	key
		 * @return
		 */
		public static function getData(key:String):BitmapSpriteInfo
		{
			return data[key];
		}
		
		/**
		 * 取得动画位图数据
		 * @param	key
		 * @return
		 */
		public static function getDataBytes(key:String):ByteArray
		{
			return data[key];
		}
		
	}

}