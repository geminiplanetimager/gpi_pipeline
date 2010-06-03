""" Remember logger messages """
# $Id: CumulativeLogger.py,v 1.1 2010/04/29 07:42:55 gpi Exp $
import logging
import StringIO

class CumulativeLoggerHandler(logging.Handler):
  """ Provide a Logging handler """

  def __init__(self, main):
    """ Remember reference to the main object """
    logging.Handler.__init__(self)
    self.main = main

  def emit(self, record):
    """ Process a log message """
    self.main.addItem(record)

class CumulativeLogger:
  """ Provide cumulative logger interface """

  def __init__(self):
    """ Create, initialize and attach cumulative logger """
    self.items = []
    h = CumulativeLoggerHandler(self)
    logging.getLogger().addHandler(h)

  def addItem(self, record):
    """ Remember a log item """
    print '--- '+str(record)
    self.items.append(record)

  #def getText(self, fmt='%(asctime)s %(message)s', datefmt='%H:%M:%S'):
  def getText(self, fmt='%(message)s', datefmt='%H:%M:%S'):
    """ Convert log messages to text. On formats see logger.Formatter """
    f   = logging.Formatter(fmt, datefmt)
    buf = StringIO.StringIO()
    b   = 0
    for item in self.items:
      if b:
         buf.write('\n')
      buf.write(f.format(item))
      b = 1
    text = buf.getvalue()
    buf.close()
    return text
