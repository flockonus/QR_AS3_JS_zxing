package 
{
	import flash.display.Sprite;
	import flash.events.Event;
	import com.google.zxing.common.flexdatatypes.HashTable;
	import flash.display.*;
	import flash.display.BitmapData;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.utils.*;
	import flash.external.ExternalInterface;
	
	import com.google.zxing.common.GlobalHistogramBinarizer;
	import com.google.zxing.common.ByteMatrix;
	import com.google.zxing.client.result.ParsedResult;
	import com.google.zxing.client.result.ResultParser;
	import com.google.zxing.DecodeHintType;
	import com.google.zxing.BarcodeFormat;
	import com.google.zxing.BinaryBitmap;
	import com.google.zxing.BufferedImageLuminanceSource;
	import com.google.zxing.MultiFormatReader;
	import com.google.zxing.MultiFormatWriter;
	import com.google.zxing.Result;

	
	/**
	 * ...
	 * @author FabianoPS
	 */
	public class Main extends Sprite 
	{
		
		private var videoDisplay:Video
		private var camera:Camera
		private var myReader:MultiFormatReader;
		// DEBUG
		//var bitmapData:BitmapData
		//var bitmap:Bitmap
		private var qrCallback:String
		private var qrErrorCb:String
		private var intervalPointer:uint;
		
		
		public function Main():void 
		{
			ExternalInterface.addCallback("start", init)
			ExternalInterface.addCallback("stop", stop)
			//if (stage) init();
			//else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		public function init( cbString:String, interval:Number=500, cbErrorString:String=null):void 
		{
			qrCallback = cbString
			qrErrorCb = cbErrorString
			myReader = new MultiFormatReader();
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			videoDisplay = new Video( 640, 480);
			if ( cameraOn() ) {
				// wait 1sec to start!
				setTimeout( function():void {
					//cameraOn()
					// now, every x sec, try decoding
					intervalPointer = setInterval( decodeSnapshot, interval );
				}, 1000 )
			}
		}
		
		private function cameraOn():Boolean {
			camera = Camera.getCamera();
			if (camera) 
			{
				if ((camera.width == -1) && ( camera.height == -1))
				{
					// no webcam seems to be attached -> hide videoDisplay
					videoDisplay.width  = 0;
					videoDisplay.height = 0;
					trace('Camera missing')
					if ( qrErrorCb ) {
						ExternalInterface.call( qrErrorCb, 'Camera missing')
					}
					return false
				}
				else
				{
					// webcam detected
					
					// change the default mode of the webcam
					camera.setMode( 640, 480, 15, true)
					camera.setQuality( 0, 100 )
					
					trace('camera')
					trace(camera.width)
					trace(camera.height)
					trace(camera.quality)
					
					videoDisplay.width  = camera.width;
					videoDisplay.height = camera.height;
					videoDisplay.attachCamera(camera);
					addChild(videoDisplay);
					return true
				}
			} else {
				trace("You don't seem to have a webcam.");
				if ( qrErrorCb ) {
					ExternalInterface.call( qrErrorCb, "You don't seem to have a webcam.")
				}
				return false
			}
		}
		
		public function stop():void {
			clearInterval( intervalPointer )
			removeChild( videoDisplay )
			videoDisplay = null
			camera = null
		}
		
		
		public function decodeBitmapData(bmpd:BitmapData, width:int, height:int):void
    	{
    		// create the container to store the image data in
        	var lsource:BufferedImageLuminanceSource = new BufferedImageLuminanceSource(bmpd);
			//trace( lsource.getMatrix() )
			
        	// convert it to a binary bitmap
        	var bitmap:BinaryBitmap = new BinaryBitmap(new GlobalHistogramBinarizer(lsource));
        	// get all the hints
			var ht:HashTable = new HashTable();
			ht.Add(DecodeHintType.POSSIBLE_FORMATS, BarcodeFormat.QR_CODE);
			ht.Add(DecodeHintType.TRY_HARDER,       true);
    		//ht = this.getAllHints()
			//ht = null
    		var res:Result = null;
    		try
    		{
    			// try to decode the image
    			res = myReader.decode(bitmap,ht);
    		}
    		catch(e:Error)
    		{
				trace(e)
    			// failed
    		}
    		
    		// did we find something?
    		if (res == null)
    		{
    			// no : we could not detect a valid barcode in the image
    			trace("<<No decoder could read the barcode>>")
				ExternalInterface.call(qrCallback, null)
    		}
    		else
    		{
    			// yes : parse the result
    			var parsedResult:ParsedResult = ResultParser.parseResult(res);
    			// get a formatted string and display it in our textarea
    			trace(parsedResult.getDisplayResult());
				ExternalInterface.call(qrCallback, parsedResult.getDisplayResult())
    		}
		}
		
		private function decodeSnapshot():void
		{
			// try to decode the current snapshpt
			var bmd:BitmapData = new BitmapData(videoDisplay.width, videoDisplay.height, false);
			bmd.draw(videoDisplay);
			decodeBitmapData(bmd, videoDisplay.width, videoDisplay.height);
		}
		
	}
	
}