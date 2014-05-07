package models
{
	import com.pamakids.models.BaseVO;
	
	public class SongVO extends BaseVO
	{
		public function SongVO()
		{
			super();
		}
		
		public var url:String;
		public var cover:String;
		public var time:String;
		public var name:String;
		public var playTime:String;
	}
}