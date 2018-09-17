package com.iflashigame.utils 
{
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.symmetric.ICipher;
	import com.hurlant.crypto.symmetric.IPad;
	import com.hurlant.crypto.symmetric.IVMode;
	import com.hurlant.crypto.symmetric.PKCS5;
	import com.hurlant.util.Base64;
	import com.hurlant.util.Hex;
	import flash.utils.ByteArray;
	/**
	 * AES加解密工具包
	 * 运行时需要hurlant的crypto  ActionScript工具包
	 * @author 闪刀浪子
	 */
	public class AESTools 
	{
		private static var CIPHER:String = "aes128-cbc";
		/**
		 * AES128-CBC-pkcs5方式加密
		 * @param	plainText		需要加密的字符串明文
		 * @param	key				密钥字符串
		 * @param	iv				初始化向量字符串
		 * @param	charSet			写入str使用的字符集
		 * @return	加密后的数据的Base64编码
		 */
		public static function encrypt(plainText:String, key:String, iv:String, charSet:String = "gbk"):String
		{
			var keyBin:ByteArray = Hex.toArray(Hex.fromString(key));
			var pad:IPad = new PKCS5;
			var mode:ICipher = Crypto.getCipher(CIPHER, keyBin, pad );
			pad.setBlockSize(mode.getBlockSize());
			
			if (mode is IVMode) 
			{
				var ivmode:IVMode = mode as IVMode;
				ivmode.IV = Hex.toArray(Hex.fromString(iv));
			}
			
			var bytes:ByteArray = new ByteArray;
			bytes.writeMultiByte(plainText,charSet);
			mode.encrypt(bytes);
			
			return Base64.encodeByteArray(bytes);
		}
		
		/**
		 * AES128-CBC-pkcs5方式解密
		 * @param	cipherText		密文
		 * @param	key				密钥
		 * @param	iv				初始化向量
		 * @param	charSet			输出字符集
		 * @return	明文
		 */
		public static function decrypt(cipherText:String, key:String, iv:String, charSet:String = "gbk"):String
		{
			var pad:IPad = new PKCS5;
			var keyBin:ByteArray = Hex.toArray(Hex.fromString(key));
			var mode:ICipher = Crypto.getCipher(CIPHER, keyBin, pad);
			pad.setBlockSize(mode.getBlockSize());
			
			if (mode is IVMode)
			{
				var ivmode:IVMode = mode as IVMode;
				ivmode.IV = Hex.toArray(Hex.fromString(iv));
			}
			
			var bytes:ByteArray = Base64.decodeToByteArray(cipherText);
			mode.decrypt(bytes);
			bytes.position = 0;
			
			return bytes.readMultiByte(bytes.length, charSet);
		}
	}
}
