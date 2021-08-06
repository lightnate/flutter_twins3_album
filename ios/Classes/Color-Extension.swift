import Foundation

class ColorUtil {
    class func getColorByInt(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) -> UIColor {
        
        let red = r / 255
        let green = g / 255
        let blue = b / 255
        
        return UIColor(red: red, green: green, blue: blue, alpha: a)
    }
    
    class func colorFromRGB(_ rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension UIColor {
    public static let transparent = ColorUtil.getColorByInt(r: 0, g: 0, b: 0, a: 0)
    public static let primary = ColorUtil.getColorByInt(r: 0, g: 179, b: 119, a: 1)
    public static let primary_99 = ColorUtil.getColorByInt(r: 0, g: 179, b: 119, a: 0.6)
    
    @available(iOS 13.0, *)
    static let b20 = UIColor { (trait) -> UIColor in
        if trait.userInterfaceStyle == .light{
            return b_20
        } else {
            return .white
        }
    }
    
    @available(iOS 13.0, *)
    static let b60 = UIColor { (trait) -> UIColor in
        if trait.userInterfaceStyle == .light{
            return b_60
        } else {
            return .white
        }
    }
  
    public static let b_20 = ColorUtil.getColorByInt(r: 51, g: 51, b: 51, a: 1)
    public static let b_60 = ColorUtil.getColorByInt(r: 153, g: 153, b: 153, a: 1)
}
