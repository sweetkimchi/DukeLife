//
//  ScrollViewController.swift
//  dukeLife
//
//  Created by Isabella Geraci on 11/9/20.
//

import UIKit

class ScrollViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var img: UIImage = UIImage(named: "Default")!
    var imgs = [UIImage]();
    var index = 0;
    var frame: CGRect = CGRect(x:0, y:0, width:0, height:0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePageControl()
        scrollView.delegate = self
        scrollView.isPagingEnabled = true

        for index in 0..<imgs.count {
            frame.origin.x = self.scrollView.frame.size.width * CGFloat(index)
            frame.size = self.scrollView.frame.size
            let subView = UIImageView(frame: frame)
            subView.image = imgs[index]
            subView.contentMode = UIView.ContentMode.scaleAspectFill
            self.scrollView .addSubview(subView)
        }

        self.scrollView.contentSize = CGSize(width:self.scrollView.frame.size.width * CGFloat(self.imgs.count), height: self.scrollView.frame.size.height)
        pageControl.addTarget(self, action: #selector(self.changePage(sender:)), for: UIControl.Event.valueChanged)
    }

    func configurePageControl() {
        self.pageControl.numberOfPages = imgs.count
        self.pageControl.currentPage = index
        self.pageControl.pageIndicatorTintColor = UIColor.black
        self.pageControl.currentPageIndicatorTintColor = blue
        self.view.addSubview(pageControl)
        let x = CGFloat(self.pageControl.currentPage) * self.scrollView.frame.size.width
        self.scrollView.setContentOffset(CGPoint(x: x,y :0), animated: false)
    }

    @objc func changePage(sender: AnyObject) -> () {
        let x = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
            scrollView.setContentOffset(CGPoint(x:x, y:0), animated: true)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
}
