""" View Log """
# $Id: ViewLog.py,v 1.2 2010/04/29 08:35:33 gpi Exp $
import Tkinter
import tkSimpleDialog
import ScrolledText
import gettext
_ = gettext.gettext

class ViewLog(tkSimpleDialog.Dialog):
  """ Display log messages of a program """

  def __init__(self, parent, log, geometry='+650+50',timestep=100):
    """ Create and display window. Log is CumulativeLogger. """
    self.log = log
    self.root = Tkinter.Tk()
    self.root.geometry(geometry)
    self.root.title("Installer Log")
    frame = Tkinter.Frame(self.root, padx=10, pady=10)

    master=frame

    master.pack_configure(fill=Tkinter.BOTH, expand=1)
    self.t = ScrolledText.ScrolledText(master, width=60, height=45) #, sticky=(Tkinter.N,Tkinter.S,Tkinter.E,Tkinter.W))
    self.t.insert(Tkinter.END, self.log.getText())
    self.t.configure(state=Tkinter.DISABLED)
    self.t.see(Tkinter.END)
    self.t.pack(fill=Tkinter.BOTH)

    self.currtext=""

    self.root.update()

    self.timestep=timestep
    self.aw_alarm = self.root.after(self.timestep,self.checkLog)

  def checkLog(self):
    newtext =  self.log.getText()
    if self.currtext != newtext:
        self.t.configure(state=Tkinter.NORMAL)
        self.t.delete('1.0',Tkinter.END)
        self.t.insert(Tkinter.END, self.log.getText())
        self.t.configure(state=Tkinter.DISABLED)
        self.t.see(Tkinter.END)
        self.currtext=newtext
    self.aw_alarm = self.root.after(self.timestep,self.checkLog)


if __name__ == '__main__':
  #
  # Create log entries
  #
  import CumulativeLogger
  import logging
  logging.basicConfig()
  l = logging.getLogger()
  l.setLevel(logging.INFO)
  cl = CumulativeLogger.CumulativeLogger()
  for i in range(100):
    l.info('log entry %i' % i)
  #
  # Create GUI
  #
  root = Tkinter.Tk()
  ViewLog(root, cl)
