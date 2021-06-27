//
//  ViewController.swift
//  ML_0
//
//  Created by Interactech on 21/06/2021.
//

import UIKit
import BbhGMl

class ViewController: UIViewController {
    
    private let semaphore = DispatchSemaphore(value: 1)
    
    private let numOfAgents = 400
   
    private var target = "To be, or not to be." // "To be, or not to be, that is the question?!: Whether 'tis nobler in the mind to suffer The slings and arrows of outrageous fortune, Or to take Arms against a Sea of troubles, And by opposing end them: to die, to sleep; No more; and by a sleep, to say we end The heart-ache, and the thousand natural shocks That Flesh is heir to? 'Tis a consummation Devoutly to be wished." //String.random(length: Int.random(in: 6...30))
    
    private var poll: MlPoll<String>!
    
    private var startTime: Date!
    
    private var gView: UIView!
    
    private var collection: UICollectionView?
    
    private var bestCellIndex = 0
    
    private var done: Bool = false
    
    private var timer: Timer!
    
    private var scroll: UIScrollView!
    
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var body: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetButton.isHidden = true
        
        body.numberOfLines = 0
        body.lineBreakMode = .byWordWrapping
        
        body.layer.borderWidth = 0.7
        body.layer.borderColor = UIColor.black.cgColor
        
        let text = "Size of poll: \(numOfAgents)\n\nTarget: \(target)\n\nLength: \(target.length())\n\nGuess: \("Processing...")"
        
        body.text = text
        
        time.textColor = .orange
        
        time.textAlignment = .natural
        
        time.text = "§Time: 0 Sec׳§"
        
        poll = MlPoll(num: numOfAgents)
        
        poll.delegate = self
        
        poll.decisionHandler = { [weak self] index in
            guard let strongSelf = self else { return true }
            return index > Int.random(in: 0..<strongSelf.target.count)
        }
        
        poll.start(target: target, lengthLimit: target.count)
        
        poll.finish = { [self] agent, val, lettersIndexs, done in
            //            guard collection == nil else { return }
            DispatchQueue.main.async {
                update(guess: agent.getData()!, string: val, lettersIndexs: lettersIndexs, done: done)
            }
        }
        
        startTime = Date()
        
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer(timeInterval: 0.0001, repeats: true) { [self] (_) in
            guard collection == nil, !done, startTime != nil else { return }
            DispatchQueue.main.async {
                time.text = "Time: \(String(format: "%.2f", Date() - startTime)) Sec׳"
                let displayData = poll.getUpdatedData()
                update(guess: displayData.guess, string: displayData.val, lettersIndexs: displayData.lettersIndexs, done: displayData.done)
            }
        }
        
        RunLoop.current.add(timer, forMode: .common)
    }
    
    @IBAction private func graphic() {
        guard collection == nil else { return }
        
        bestCellIndex = 0
        
        gView = UIView(frame: view.frame)
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.systemMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = gView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        body.alpha = 0.2
        blurEffectView.alpha = 0.88
        gView.addSubview(blurEffectView)
        //        gView.addSubview(blurEffectView)
        //        gView.addSubview(blurEffectView)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionHeadersPinToVisibleBounds = true
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        collection = UICollectionView(frame: gView.frame, collectionViewLayout: layout)
        
        collection!.register(UINib(nibName: "Header", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        
        gView.addSubview(collection!)
        
        collection!.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        
        collection!.dataSource = self
        
        collection!.delegate = self
        
        collection!.register(UINib(nibName: "AgentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "Cell")
        
        if !done {
            RunLoop.current.add(Timer(timeInterval: 0.4, repeats: true) { (timer: Timer) in
                guard !self.done, let collection = self.collection else {
                    timer.invalidate()
                    return
                }
                DispatchQueue.main.async {
                    collection.reloadData()
                }
            }, forMode: .common)
        }
        
        gView.backgroundColor = .clear
        
        view.addSubview(gView)
        
        let swipeL = UISwipeGestureRecognizer(target: self, action: #selector(closeView))
        swipeL.direction = .left
        let swipeR = UISwipeGestureRecognizer(target: self, action: #selector(closeView))
        swipeR.direction = .right
        gView.addGestureRecognizer(swipeL)
        gView.addGestureRecognizer(swipeR)
    }
    
    @objc private func closeView() {
        collection = nil
        body.alpha = 1
        gView.removeFromSuperview()
    }
    
    @IBAction func reset(button: UIButton) {
        semaphore.signal()
        resetButton.isHidden = true
        startTime = Date()
        target = String.random(length: Int.random(in: 6...30), extra: nil)
        poll.resetAgents()
        poll.start(target: target, lengthLimit: target.count)
        done = false
        startTimer()
    }
}

extension ViewController: PollUpdates {
    func update(guess: String, string: String,lettersIndexs: [Int], done: Bool) {
        semaphore.wait()
        guard !self.done else { return }
        self.done = done
        if done {
            poll.sortAgents()
            DispatchQueue.main.async { [self] in
                collection?.reloadData()
            }
            print("Done!!!")
            
            timer.invalidate()
            timer = nil
            
            resetButton.isHidden = false
        }
        
        let atter = NSMutableAttributedString(string: guess)
        for index in lettersIndexs {
            atter.addAttributes([.foregroundColor: UIColor.systemGreen], range: NSRange(location: index, length: 1))
        }
        
        let text = "Size of poll: \(numOfAgents)\n\nLength: \(target.count)\n\nTarget: \(target)\n\n\(string)"
        let newAtter = NSMutableAttributedString(string: text)
        newAtter.replaceCharacters(in: (text as NSString).range(of: "{%@}"), with: atter)
        
        let rangeOfTarget = (newAtter.string as NSString).range(of: target)
        for index in lettersIndexs {
            newAtter.addAttributes([.foregroundColor: UIColor.systemPurple], range: NSRange(location: rangeOfTarget.location + index, length: 1))
        }
        
        DispatchQueue.main.async { [self] in
            //                collection?.reloadData()
            body.attributedText = newAtter
        }
        semaphore.signal()
    }
}

extension Date {
    
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    internal func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! Header
        
        headerView.text.text = "Number Of Agents: \(numOfAgents)\nGeneration: \(poll.getGeneration())\nBest: \(String(format: "%.6f",poll.getBest()?.fitnessVal ?? 0))"
        
        headerView.backgroundColor = UIColor.white.withAlphaComponent(0.64)
        
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return poll.getAgents().count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! AgentCollectionViewCell
        
        let arr = poll.getAgents()
        if indexPath.row < arr.count {
            if arr[bestCellIndex].fitnessVal! < arr[indexPath.row].fitnessVal! || arr[indexPath.row].getData() == target {
                cell.container.backgroundColor = UIColor(hexString: "#FFD479", alpha: 0.54)
                bestCellIndex = indexPath.row
            }
            cell.num.text = "Agent Num: \(indexPath.row)"
            cell.set(title: arr[indexPath.row].getData() ?? "", sub: "\(arr[indexPath.row].fitnessVal ?? 0)")
            
            //        if done {
            //            print("\(indexPath.row): \(arr[indexPath.row].toString())")
            //        }
            
            cell.container.alpha = 0
            
            UIView.animate(withDuration: 0.001) {
                cell.container.alpha = 1
            }
            
            cell.container.backgroundColor = indexPath.row == bestCellIndex ? UIColor.green.withAlphaComponent(0.54) : UIColor(hexString: "#FFD479", alpha: 0.54)
        }
        
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width / 3.6, height: view.frame.height / 4.8)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 80)
    }
}

extension ViewController: UICollectionViewDelegate {
    
}

extension UIColor {
    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        let hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format:"#%06x", rgb)
    }
}

extension StringProtocol {
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
    subscript(range: Range<Int>) -> SubSequence {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        return self[startIndex..<index(startIndex, offsetBy: range.count)]
    }
    subscript(range: ClosedRange<Int>) -> SubSequence {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        return self[startIndex..<index(startIndex, offsetBy: range.count)]
    }
    subscript(range: PartialRangeFrom<Int>) -> SubSequence { self[index(startIndex, offsetBy: range.lowerBound)...] }
    subscript(range: PartialRangeThrough<Int>) -> SubSequence { self[...index(startIndex, offsetBy: range.upperBound)] }
    subscript(range: PartialRangeUpTo<Int>) -> SubSequence { self[..<index(startIndex, offsetBy: range.upperBound)] }
}

extension String: DNA {
    
    public var isCompletedTask: ((String) -> (Bool))? {
        get {
            return nil
        }
        set {}
    }
    
    
    public var isFinish: ((String) -> (Bool))? {
        get { return nil }
        set {}
    }
    
    public func cleanBetweenGens() {}
    
    public var extra: Any? {
        get { return nil }
        set {}
    }
    
    public func printDescription() {
//        print("Description: \(self)")
    }
    
    public init(copy string: String) {
        self = string
    }
    
//    public static func emptyChromosome() -> Chromosome {
//        return ""
//    }
    
    public static func random(length: Int, extra: Any?) -> String {
        return randomString(length: length, targetLength: 0, numOfWorkers: 0)
    }
    
    private static func randomString(length: Int, targetLength: Int, numOfWorkers: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyz'ABCDEFGHIJKLMNOPQRSTUVWXYZ; .,?:@#$%^&*()_+=-±!0123456789\n    "
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        //        var repeatFlag = true
        //        while repeatFlag {
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
            //                if targetLength >= 0 {
            //                    randomFix![randomString] = randomFix![randomString] ?? 0
            //                }
            //            }
            //            if targetLength < 0 {
            //                repeatFlag = false
            //            }
            //            else {
            //                randomFix![randomString]! += 1
            //                let randomRatio: CGFloat = CGFloat(randomFix![randomString]!) / CGFloat(targetLength)
            //                let multi: CGFloat = CGFloat(numOfWorkers / targetLength) * ratio
            //                repeatFlag = randomRatio * multi >= 1
            //
            ////                print("value: char: \(randomString) : score: \(randomFix![randomString] ?? 0), randomRatio: \(randomRatio), multi: \(multi), total: \(randomRatio * multi)")
            //
            //                if repeatFlag {
            ////                    print("Stop... value: char: \(randomString) : score: \(randomFix![randomString] ?? 0), randomRatio: \(randomRatio), multi: \(multi), total: \(randomRatio * multi)")
            //                    randomFix![randomString]! /= 10
            //                }
            //            }
        }
        
        return randomString
    }
    
    public static func +=(lhs: inout String, rhs: String) {
        lhs = lhs + rhs
    }
    
//    public static func +=(lhs: inout String, rhs: Chromosome) {
//        lhs = lhs + (rhs as! String)
//    }
//
    public static func ==(lhs: String, rhs: String) -> Bool {
        return lhs.elementsEqual(rhs)
    }
    
    public subscript(offset: Int) -> String {
        get {
            return "\(self[index(startIndex, offsetBy: offset)])"
        }
        set {
            self = (self as NSString).replacingCharacters(in: NSRange(location: offset, length: 1), with: newValue)
        }
    }
    
    public static func empty() -> String {
        return ""
    }
    
    public func length() -> Int {
        return count
    }
    
    func elementsEqual(other: String) -> Bool {
        return elementsEqual(other)
    }
    
    public func calcFitness(val: String?, best: CGFloat) -> (val: CGFloat, extraDimension: CGFloat) {
        guard let  val = val else { return (0, 0) }
        var count: CGFloat = 0.1
        
        for i in 0..<val.count {
            if self[i] == val[i] {
                count += 1
            }
        }
        let x = count / CGFloat(val.count)
        return (best * (x / best) / CGFloat(val.count), CGFloat(Int(count)))
    }
    
    public func mutate(rate: CGFloat) -> Self {
        
        //        guard let val = val else { return "" }
        
        var tempVal = ""
        
        for i in 0..<length() {
            let c = self[i] as Character
            
            let r = CGFloat.random(in: 0...1)
            
            if r < rate {
                tempVal += String.random(length: 1, extra: nil)
            }
            else {
                tempVal += "\(c)"
            }
        }
        
        return tempVal
    }
    
    public func find(target: String, count: CGFloat) -> Bool {
        return self == target && target.length() == length()
    }
}

