import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from corvin_side_action_renderer import main


main(expected_animation="wet", expected_direction="side_right")
