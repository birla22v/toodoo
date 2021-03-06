require "toodoo/version"
require "toodoo/init_db"
require 'highline/import'
require 'pry'

module Toodoo
  class User < ActiveRecord::Base
    has_many :todo_lists
  end

  class TodoList < ActiveRecord::Base
    has_many :todo_items, dependent: :destroy
    belongs_to :user
  end

  class TodoItem < ActiveRecord::Base
    belongs_to :todo_list
  end
end

class TooDooApp
  def initialize
    @user = nil
    @todos = nil
    @show_done = nil
  end

  def new_user
    say("Creating a new user:")
    name = ask("Username?") { |q| q.validate = /\A\w+\Z/ }
    @user = Toodoo::User.create(:name => name)
    say("We've created your account and logged you in. Thanks #{@user.name}!")
  end

  def login
    choose do |menu|
      menu.prompt = "Please choose an account: "

      Toodoo::User.find_each do |u|
        menu.choice(u.name, "Login as #{u.name}.") { @user = u }
      end

      menu.choice(:back, "Just kidding, back to main menu!") do
        say "You got it!"
        @user = nil
      end
    end
  end

  def delete_user
    choices = 'yn'
    delete = ask("Are you *sure* you want to stop using TooDoo?") do |q|
      q.validate =/\A[#{choices}]\Z/
      q.character = true
      q.confirm = true
    end
    if delete == 'y'
      @user.destroy
      @user = nil
    end
  end

  def new_todo_list
    # This should create a new todo list by getting input from the user.
    # The user should not have to tell you their id.
    # Create the todo list in the database and update the @todos variable.
    title = ask("Enter new list name:"){ |q| q.validate = /\A\w+\Z/ }
    @todos = Toodoo::TodoList.create(:name => title, :user_id => @user.id)
  end

  def pick_todo_list

      #  This should get get the todo lists for the logged in user (@user).
      # Iterate over them and add a menu.choice line as seen under the login method's
      # find_each call. The menu choice block should set @todos to the todo list.
      choose do |menu|
      menu.prompt = "Please choose a list: "

      @user.toodoo_lists.find_each do |list|
        menu.choice(title, "List Chosen: #{title}.") { @todos = list }
      end

      menu.choice(:back, "Just kidding, back to the main menu!") do
        say "You got it!"
        @todos = nil
      end
    end
  end

  def delete_todo_list
    # This should confirm that the user wants to delete the todo list.
    # If they do, it should destroy the current todo list and set @todos to nil.
    msg = "Would you like to delete this list? Enter y or n"
    choice = ask(msg){ |q| q.validate = /\A\[yn]\Z/ }
    if choice == 'y'
      @todos.destroy
      @todos = nil
    end
  end

  def new_task
    # This should create a new task on the current user's todo list.
    # It must take any necessary input from the user. A due date is optional.
    task= ask("Enter task: ")
    msg = "Would you like to add a due date? Enter y or n"
    option = ask(msg){ |q| q.validate = /\A\[yn]\Z/ }
    if option == 'y'
      msg2 = "Enter date in this format MM/DD/YYYY"
      date = ""
      date = ask(msg2){ |q| q.validate = ^(0[1-9]|1[012])/(0[1-9]|[12][0-9]|3[01])/(20)\d\d$ }
      Toodoo::TodoItem.create(:name => task, :date_due => date, :todo_list_id => @todos.id, :done => false)
    end
  end

  ## NOTE: For the next 3 methods, make sure the change is saved to the database.
  def mark_done
    # This should display the todos on the current list in a menu
    # similarly to pick_todo_list. Once they select a todo, the menu choice block
    # should update the todo to be completed.
    item = ask("Please choose an item to mark done: ")
    if item == name
      item.done = true
      item.save
    end
  end

  def change_due_date
    # This should display the todos on the current list in a menu
    # similarly to pick_todo_list. Once they select a todo, the menu choice block
    # should update the due date for the todo. You probably want to use
    # `ask("foo", Date)` here.
    item = ask("Which item would you like to change the due date for")
    if item == name
      msg = "Enter changed date in this format MM/DD/YYYY"
      date = ""
      date = ask(msg){ |q| q.validate = ^(0[1-9]|1[012])/(0[1-9]|[12][0-9]|3[01])/(20)\d\d$ }
      item.date_due = date
      item.save
    end
  end

  def edit_task
    # This should display the todos on the current list in a menu
    # similarly to pick_todo_list. Once they select a todo, the menu choice block
    # should change the name of the todo.
    item = ask("Which item would you like to change the name for")
    if item == name
      msg = "Enter new name"
      new_name = ask(message){ |q| q.validate = /\A\w+\Z/ }
      item.name = new_name
      item.save
    end
  end

  def show_overdue
    # This should print a sorted list of todos with a due date *older*
    # than `Date.now`. They should be formatted as follows:
    # "Date -- Eat a Cookie"
    # "Older Date -- Play with Puppies"

    #get date now
    #get previous date
    #order them
    #if due date was before date now, puts overdue
  end

  def run
    puts "Welcome to your personal TooDoo app."
    loop do
      choose do |menu|
        menu.layout = :menu_only
        menu.shell = true

        # Are we logged in yet?
        unless @user
          menu.choice(:new_user, "Create a new user.") { new_user }
          menu.choice(:login, "Login with an existing account.") { login }
        end

        # We're logged in. Do we have a todo list to work on?
        if @user && !@todos
          menu.choice(:delete_account, "Delete the current user account.") { delete_user }
          menu.choice(:new_list, "Create a new todo list.") { new_todo_list }
          menu.choice(:pick_list, "Work on an existing list.") { pick_todo_list }
          menu.choice(:remove_list, "Delete a todo list.") { delete_todo_list }
        end

        # Let's work on some todos!
        if @todos
          menu.choice(:new_task, "Add a new task.") { new_task }
          menu.choice(:mark_done, "Mark a task finished.") { mark_done }
          menu.choice(:move_date, "Change a task's due date.") { change_due_date }
          menu.choice(:edit_task, "Update a task's description.") { edit_task }
          menu.choice(:show_done, "Toggle display of tasks you've finished.") { @show_done = !!@show_done }
          menu.choice(:show_overdue, "Show a list of task's that are overdue, oldest first.") { show_overdue }
          menu.choice(:back, "Go work on another Toodoo list!") do
            say "You got it!"
            @todos = nil
          end
        end

        menu.choice(:quit, "Quit!") { exit }
      end
    end
  end
end

binding.pry

todos = TooDooApp.new
todos.run
