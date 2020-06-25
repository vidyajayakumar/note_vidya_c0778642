

import UIKit
import CoreData
import MapKit
import AVKit
import AVFoundation

class noteViewController: UIViewController, UITextFieldDelegate,  UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate, CLLocationManagerDelegate, AVAudioRecorderDelegate {
    
    
    private let noteDateTime : Int64 = Date().toSeconds()
    
    @IBOutlet weak var noteDateLabel: UILabel!
    @IBOutlet weak var noteCategoryLabel: UILabel!
    
    @IBOutlet weak var noteInfoView: UIView!
    @IBOutlet weak var noteImageViewView: UIView!
    
    @IBOutlet weak var noteNameLabel: UITextField!
    @IBOutlet weak var noteDescriptionLabel: UITextView!
    
    @IBOutlet weak var noteImageView: UIImageView!
    
    @IBOutlet weak var noteMapView: MKMapView!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var noteRecord: UIButton!
    @IBOutlet weak var noteRecordButton: UIBarButtonItem!
    @IBOutlet weak var noteCategoryButton: UIBarButtonItem!
    
    var managedObjectContext: NSManagedObjectContext? {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
    }

    
    var noteCurrentLoc: CLLocationCoordinate2D!
    private let locationManager = CLLocationManager()
    var notesFetchedResultsController: NSFetchedResultsController<Note>!
    var notes = [Note]()
    var note: Note?
    var isExsisting = false
    var indexPath: Int?
    var noteCatSelected: String = "Others"
//    var recordButton: UIButton!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var noteUuid: String = ""
    var noteAudioFile: String = ""

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get Date
        let date = getNoteDate(date: Date.init(seconds: noteDateTime))
//        print("Date: ",date)
        
        
        // Load data from Tableview
        if let note = note {
            noteNameLabel.text = note.noteName
            noteDescriptionLabel.text = note.noteDescription
            noteImageView.image = UIImage(data: note.noteImage! as Data)
            noteDateLabel.text = note.noteDate
            var temp: String = ("Category: ")
            temp.append(note.noteCategory!)
            noteCategoryLabel.text = temp
            noteAnnotation(noteCoordinate: CLLocationCoordinate2D(latitude: note.noteLocLat , longitude: note.noteLocLong ))
            noteUuid = String(note.noteUUID ?? "")
            noteAudioFile = String(note.noteAudio ?? "")
        }
        else{    // Creating new
            noteDateLabel.text = getNoteDate(date: Date.init(seconds: noteDateTime))
            print("Date: ",date)
            noteCategoryLabel.text = "Category: Others"
            // TODO: load Map location
            getCurrentLocation()
            noteUuid = UUID().uuidString
            print(noteUuid)
        }
        
        if noteNameLabel.text != "" {
            isExsisting = true
        }
        
        // Record session
        recordSession()
        
        // Delegates
        noteNameLabel.delegate = self
        noteDescriptionLabel.delegate = self
        
        // Styles
        noteInfoView.layer.shadowColor =  UIColor(red:0/255.0, green:0/255.0, blue:0/255.0, alpha: 1.0).cgColor
        noteInfoView.layer.shadowOffset = CGSize(width: 0.75, height: 0.75)
        noteInfoView.layer.shadowRadius = 1.5
        noteInfoView.layer.shadowOpacity = 0.2
        noteInfoView.layer.cornerRadius = 2
        
        noteImageViewView.layer.shadowColor =  UIColor(red:0/255.0, green:0/255.0, blue:0/255.0, alpha: 1.0).cgColor
        noteImageViewView.layer.shadowOffset = CGSize(width: 0.75, height: 0.75)
        noteImageViewView.layer.shadowRadius = 1.5
        noteImageViewView.layer.shadowOpacity = 0.2
        noteImageViewView.layer.cornerRadius = 2

        noteImageView.layer.cornerRadius = 2
        
        noteNameLabel.setBottomBorder()

    }
    
    
    @IBAction func noteRecordPressed(_ sender: UIButton) {
//        loadRecordingUI()
        playSound()
    }
    @IBAction func recordButtonPressed(_ sender: Any) {
//        loadRecordingUI()
    }
    @IBAction func categoryButtonPressed(_ sender: Any) {
        selectCategory()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

    // Record --------------------
    
    func recordSession() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            
            //            try recordingSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
//            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [])
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                    } else {
                        // failed to record!
//                        print("record error\(error)")
                    }
                }
            }
        } catch {
            // failed to record!
            print("record error\(error)")
        }
    }
    
    func loadRecordingUI() {
//        recordButton = UIButton(frame: CGRect(x: 64, y: 64, width: 128, height: 64))
        recordButton.setTitle("Tap to Record", for: .normal)
        recordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
//        view.addSubview(recordButton)
        
    }
    
    func startRecording() {
        var ext = "recording"
        ext.append(noteUuid)
        ext.append(".m4a")
        let audioFilename = getDocumentsDirectory().appendingPathComponent(ext)
        noteAudioFile = audioFilename.absoluteString
//        do {try noteAudioFile = String(contentsOf: audioFilename)} catch {print("audiofile error\(error)")}
        print(noteAudioFile)
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            recordButton.setTitle("Tap to Stop", for: .normal)
        } catch {
            finishRecording(success: false)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(paths[0])
        return paths[0]
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        if success {
            recordButton.setTitle("Tap to Re-record", for: .normal)
        } else {
            recordButton.setTitle("Tap to Record", for: .normal)
            // recording failed :(
        }
    }
    
    func delFile(){
        do{
            try FileManager.default.removeItem(at: URL(fileURLWithPath: noteAudioFile))
        } catch{
            print("Audio Deleting Error\(error)")
        }
    }
    
    @objc func recordTapped() {
        if audioRecorder == nil {
            if (noteAudioFile == "")
            {   startRecording()    }
            else
            {
                delFile()
                startRecording()
            }
        } else {
            finishRecording(success: true)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    var player: AVAudioPlayer?
    
    func playSound() {
        guard let url = URL(string: noteAudioFile) else { return }
        print(url)
        do {
//            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    // Record end ----------------
    
    //   get location     ----------------------
    func getCurrentLocation() {
        locationManager.delegate = self
        
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }else if status == .authorizedAlways || status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: locationManager)
                        _ = locationManager.location?.coordinate
        }
    }
    private func beginLocationUpdates(locationManager: CLLocationManager){
        noteMapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    var currentCoordinate: CLLocationCoordinate2D?
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Did get latest Location")
        guard let latestLocation = locations.last else { return }
        currentCoordinate = latestLocation.coordinate
        zoomToLatestLocation(with: latestLocation.coordinate)
        //        locationManager.stopUpdatingLocation()
        noteCurrentLoc = currentCoordinate
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("The status changed")
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            noteMapView.showsUserLocation = true
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    private func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D){
        let zoomRegion = MKCoordinateRegionMakeWithDistance(coordinate, 2000, 2000)
        noteMapView.setRegion(zoomRegion, animated: true)
        //locationManager.stopUpdatingLocation()
        
    }
    //        ----------------------
    
    // Annotation -----------
    func noteAnnotation(noteCoordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = noteCoordinate
        noteMapView.addAnnotation(annotation)
        zoomToLatestLocation(with: noteCoordinate)
    }
    
    //    -----------------------

    // Core data
    func saveToCoreData(completion: @escaping ()->Void){
        managedObjectContext!.perform {
            do {
                try self.managedObjectContext?.save()
                completion()
                print("Note saved to CoreData.")
            }
            
            catch let error {
                print("Could not save note to CoreData: \(error.localizedDescription)")
            }
        }
    }
    
    // Category Selector
    func selectCategory(){
        
        var noteCategory: String = ""
        let categoryController = UIAlertController(title: "Select Category", message: "", preferredStyle: .actionSheet)

        let catPersonal = UIAlertAction(title: "Personal", style: .default) { (action) in
            noteCategory = "Personal"
            self.noteCategorySelected(noteCategory: noteCategory)
        }

        let catJournal = UIAlertAction(title: "Journal", style: .default) { (action) in
            noteCategory = "Journal"
            self.noteCategorySelected(noteCategory: noteCategory)
        }

        let catSchool = UIAlertAction(title: "School", style: .default) { (action) in
            noteCategory = "School"
            self.noteCategorySelected(noteCategory: noteCategory)
        }

        let catImportant = UIAlertAction(title: "Important", style: .default) { (action) in
            noteCategory = "Important"
            self.noteCategorySelected(noteCategory: noteCategory)
        }

        let catWork = UIAlertAction(title: "Work", style: .default) { (action) in
            let noteCategory = "Work"
            self.noteCategorySelected(noteCategory: noteCategory)
        }
        
        let catOthers = UIAlertAction(title: "Others", style: .default) { (action) in
            let noteCategory = "Others"
            self.noteCategorySelected(noteCategory: noteCategory)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)

        categoryController.addAction(catWork)
        categoryController.addAction(catJournal)
        categoryController.addAction(catImportant)
        categoryController.addAction(catSchool)
        categoryController.addAction(catPersonal)
        categoryController.addAction(catOthers)

        categoryController.addAction(cancelAction)

        present(categoryController, animated: true, completion: nil)
        }
        
    func noteCategorySelected(noteCategory: String){
        print(noteCategory)
        noteCatSelected = noteCategory
        noteCategoryLabel.text = "Category: " + noteCatSelected
    }
    
    // Image Picker
    @IBAction func pickImageButtonWasPressed(_ sender: Any) {
        
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        
        let alertController = UIAlertController(title: "Add an Image", message: "Choose From", preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (action) in
            pickerController.sourceType = .camera
            self.present(pickerController, animated: true, completion: nil)
            
        }
        
        let photosLibraryAction = UIAlertAction(title: "Photos Library", style: .default) { (action) in
            pickerController.sourceType = .photoLibrary
            self.present(pickerController, animated: true, completion: nil)
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        
        alertController.addAction(cameraAction)
        alertController.addAction(photosLibraryAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.noteImageView.image = image
            
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    // Date    
    func getNoteDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: date)
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = "EEEE, MMM d, yyyy, hh:mm:ss"
        let noteDate = formatter.string(from: yourDate!)
        print(noteDate)
        return noteDate
    }
    

    // Save
    @IBAction func saveButtonWasPressed(_ sender: UIBarButtonItem) {
        if noteNameLabel.text == "" || noteNameLabel.text == "NOTE NAME" || noteDescriptionLabel.text == "" || noteDescriptionLabel.text == "Note Description..." {
            
            let alertController = UIAlertController(title: "Missing Information", message:"You left one or more fields empty. Please make sure that all fields are filled before attempting to save.", preferredStyle: UIAlertControllerStyle.alert)
            let OKAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil)
            
            alertController.addAction(OKAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        }
        
        else {
            if (isExsisting == false) {
                let noteName = noteNameLabel.text
                let noteDescription = noteDescriptionLabel.text
                
                
                if let moc = managedObjectContext {
                    let note = Note(context: moc)

                    if let data = UIImageJPEGRepresentation(self.noteImageView.image!, 1.0) {
                        note.noteImage = data as NSData as Data
                    }
                
                    note.noteName = noteName
                    note.noteDescription = noteDescription
                    note.noteDate = getNoteDate(date: Date.init(seconds: noteDateTime))
                    note.noteCategory = noteCatSelected
                    note.noteLocLat = noteCurrentLoc.latitude
                    note.noteLocLong = noteCurrentLoc.longitude
                    note.noteAudio = noteAudioFile
                
                    saveToCoreData() {
                        
                        let isPresentingInAddFluidPatientMode = self.presentingViewController is UINavigationController
                        
                        if isPresentingInAddFluidPatientMode {
                            self.dismiss(animated: true, completion: nil)
                            
                        }
                        
                        else {
                            self.navigationController!.popViewController(animated: true)
                        }
                    }
                }
            }
            else if (isExsisting == true) {
                
                let note = self.note
                
                let managedObject = note
                managedObject!.setValue(noteNameLabel.text, forKey: "noteName")
                managedObject!.setValue(noteDescriptionLabel.text, forKey: "noteDescription")
                managedObject!.setValue(noteCatSelected, forKey: "noteCategory")
                
                if let data = UIImageJPEGRepresentation(self.noteImageView.image!, 1.0) {
                    managedObject!.setValue(data, forKey: "noteImage")
                }
                
                do {
                    try context.save()
                    
                    let isPresentingInAddFluidPatientMode = self.presentingViewController is UINavigationController
                    
                    if isPresentingInAddFluidPatientMode {
                        self.dismiss(animated: true, completion: nil)
                        
                    }
                        
                    else {
                        self.navigationController!.popViewController(animated: true)
                    }
                }
                catch {
                    print("Failed to update existing note.")
                }
            }

        }

    }
    
    // Cancel
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        let isPresentingInAddFluidPatientMode = presentingViewController is UINavigationController
        delFile()
        if isPresentingInAddFluidPatientMode {
            dismiss(animated: true, completion: nil)
            
        }
        
        else {
            navigationController!.popViewController(animated: true)
        }
    }
    
    // Text field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if (textView.text == "Note Description...") {
            textView.text = ""
        }
    }
}

extension UITextField {
    func setBottomBorder() {
        self.borderStyle = .none
        self.layer.backgroundColor = UIColor.white.cgColor
        
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor(red: 245.0/255.0, green: 79.0/255.0, blue: 80.0/255.0, alpha: 1.0).cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
    }
}
extension Date {
    func toSeconds() -> Int64! {
        return Int64((self.timeIntervalSince1970).rounded())
    }
    
    init(seconds:Int64!) {
        self = Date(timeIntervalSince1970: TimeInterval(Double.init(seconds)))
    }
}
