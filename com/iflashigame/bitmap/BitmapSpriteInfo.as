package com.iflashigame.bitmap 
{
	import flash.geom.Point;
	/**
	 * 存储动画位图的完整信息
	 * @author Faster
	 */
	public class BitmapSpriteInfo 
	{
		/**
		 * 位图数据序列
		 * @param	length
		 */
		private var _vector:Vector.<BitmapSpriteFrameInfo>
		
		/**
		 * 攻击点坐标
		 */
		public var hitPoint:Point=new Point;
		
		public function BitmapSpriteInfo(length:int) 
		{
			_vector = new Vector.<BitmapSpriteFrameInfo>(length, true);
		}
		
		/**
		 * 查找标签的索引位置
		 * @param	label
		 * @return	如果没有找到则返回-1
		 */
		public function findLabel(label:String):int
		{
			var length:int = _vector.length;
			for (var i:int = 0; i < length; i++)
			{
				if (_vector[i].label == label)
				return i;
			}
			return -1;
		}
		
		/**
		 * 将位图信息添加到指定帧序号
		 * @param	index
		 * @param	bitFrameInfo
		 */
		public function addAt(index:int,bitFrameInfo:BitmapSpriteFrameInfo)
		{
			_vector[index] = bitFrameInfo;
		}
		
		/**
		 * 获取指定帧的位图信息
		 * @param	index
		 * @return
		 */
		public function getAt(index:int):BitmapSpriteFrameInfo
		{
			return _vector[index];
		}
		
		/**
		 * 获取动画的总帧数
		 */
		public function get frameCount():int
		{
			return _vector.length;
		}
		
		public function toString():String
		{
			var str:String="";
			for (var i:int = 0; i < _vector.length; i++)
			{
				str += "frame"+(i + 1).toString()+": ";
				str += _vector[i].toString();
				str += "\n";
			}
			return str;
		}
	}

}