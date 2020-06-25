

import UIKit
import CoreData

class noteTableViewController: UITableViewController {
    
    @IBOutlet weak var noteCatSorter: UIBarButtonItem!
    @IBOutlet weak var noteReloader: UIBarButtonItem!
    
    

    var notes = [Note]()
    var filteredNotes = [Note]()
    let searchController = UISearchController(searchResultsController: nil)
    let appdelegate = UIApplication.shared.delegate as! AppDelegate
    
    var managedObjectContext: NSManagedObjectContext? {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
         self.navigationItem.leftBarButtonItem = self.editButtonItem
        
//        let searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self
//        searchController.searchResultsUpdater = self
        definesPresentationContext = true
        searchController.obscuresBackgroundDuringPresentation = false
        tableView.delegate = self
        tableView.dataSource = self
                
        retrieveNotes()
        
        // Styles
        self.tableView.backgroundColor = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
        
    }
    // Button Clicks   =========================================
    @IBAction func noteCategoryButtonPressed(_ sender: UIBarButtonItem) {
        categoryTableLoad()
    }
    @IBAction func noteRefreshButtonpressed(_ sender: UIBarButtonItem) {
        retrieveNotes()
    }
    

    


    
    // Category load Selector =======================
    func categoryTableLoad(){
        
        var noteCategory: String = ""
        let categoryController = UIAlertController(title: "Select Category", message: "", preferredStyle: .actionSheet)
        
        let catPersonal = UIAlertAction(title: "Personal", style: .default) { (action) in
            noteCategory = "Personal"
            self.noteCategoryFetchTable(noteCategory: noteCategory)
        }
        
        let catJournal = UIAlertAction(title: "Journal", style: .default) { (action) in
            noteCategory = "Journal"
            self.noteCategoryFetchTable(noteCategory: noteCategory)
        }
        
        let catSchool = UIAlertAction(title: "School", style: .default) { (action) in
            noteCategory = "School"
            self.noteCategoryFetchTable(noteCategory: noteCategory)
        }
        
        let catImportant = UIAlertAction(title: "Important", style: .default) { (action) in
            noteCategory = "Important"
            self.noteCategoryFetchTable(noteCategory: noteCategory)
        }
        
        let catWork = UIAlertAction(title: "Work", style: .default) { (action) in
            let noteCategory = "Work"
            self.noteCategoryFetchTable(noteCategory: noteCategory)
        }
        
        let catOthers = UIAlertAction(title: "Others", style: .default) { (action) in
            let noteCategory = "Others"
            self.noteCategoryFetchTable(noteCategory: noteCategory)
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
    

    func noteCategoryFetchTable(noteCategory: String){
        print(noteCategory)
        
        var predicate: NSPredicate = NSPredicate()
        predicate = NSPredicate(format: "noteCategory contains[c] '\(noteCategory)'")
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedObjectContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Note")
        fetchRequest.predicate = predicate
        do {
            notes = try managedObjectContext.fetch(fetchRequest) as! [NSManagedObject] as! [Note]
        } catch let error as NSError {
            print("Could not fetch. \(error)")
        }
        tableView.reloadData()
        
    }
//    Category Table load end =========================================
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        retrieveNotes()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "noteTableViewCell", for: indexPath) as! noteTableViewCell

        let note: Note = notes[indexPath.row]
        cell.configureCell(note: note)
        cell.backgroundColor = UIColor.clear
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let note = self.notes[indexPath.row]
//            let path = getDirectory().appendingPathComponent("Recording\(indexPath.row + 1).m4a")
            context.delete(note)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            do {
                self.notes = try context.fetch(Note.fetchRequest())
            }
                
            catch {
                print("Failed to delete note.")
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
//            tableView.reloadData()
        }
        tableView.reloadData()
        
    }
    
    // MARK: NSCoding
    func retrieveNotes() {
        managedObjectContext?.perform {
            self.fetchNotesFromCoreData { (notes) in
                if let notes = notes {
                    self.notes = notes
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func fetchNotesFromCoreData(completion: @escaping ([Note]?)->Void){
        managedObjectContext?.perform {
            var notes = [Note]()
            let request: NSFetchRequest<Note> = Note.fetchRequest()
            
            do {
                notes = try  self.managedObjectContext!.fetch(request)
                completion(notes)
                
            }
            
            catch {
                print("Could not fetch notes from CoreData:\(error.localizedDescription)")
                
            }
            
        }
        
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                let noteDetailsViewController = segue.destination as! noteViewController
                let selectedNote: Note = notes[indexPath.row]
                
                noteDetailsViewController.indexPath = indexPath.row
                noteDetailsViewController.isExsisting = false
                noteDetailsViewController.note = selectedNote
            }
        }
            
        else if segue.identifier == "addItem" {
            print("User added a new note.")
        }
    }
    
    

}

extension noteTableViewController: UISearchBarDelegate, UISearchDisplayDelegate{
    // Search   =========================================

  
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if !searchText.isEmpty {
            var predicate: NSPredicate = NSPredicate()
            predicate = NSPredicate(format: "noteName contains[c] '\(searchText)' OR noteDescription contains[c] '\(searchText)'")
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let managedObjectContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Note")
            fetchRequest.predicate = predicate
            do {
                notes = try managedObjectContext.fetch(fetchRequest) as! [NSManagedObject] as! [Note]
                } catch let error as NSError {
                    print("Could not fetch. \(error)")
                }
        }
        else{
            retrieveNotes()
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        retrieveNotes()
    }


//    Search end =========================================
    
    

    
    
}
