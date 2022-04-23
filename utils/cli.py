import json
import os
import shutil
from typing import Tuple
from uuid import uuid4
import typer
import moviepy.editor as mp
from slugify import slugify

app = typer.Typer(name="Dano Drevo Soundboard CLI")


def save_sounds(sounds_file, sounds):
    with open(sounds_file, "w", encoding='utf-8') as f: 
        json.dump(sounds, f, indent=2)


def load_sounds(sounds_file):
    with open(sounds_file, "r", encoding='utf-8') as f: 
        sounds = json.load(f)
    return sounds


@app.command("create")
def create_sound_from_video(
        title: str = typer.Option(..., prompt="Enter sound title"),
        video_file: str = typer.Option(..., prompt="Enter path to video file"),
        start_time: str = typer.Option("00:00:00", prompt="Enter clip start time", formats=["%d:%d:%f"]),
        duration: float = typer.Option(-1, prompt="Enter duration of the clip, in seconds", show_default=False),
        image: str = None,
        tweak: bool = False,
        format: str = '.mp3'
    ):
    """Create a sound from video and add it to the index."""
    video_file = video_file.strip('"')
    with mp.VideoFileClip(video_file) as original_video:
        video = original_video.subclip(t_start=start_time)
        if duration > 0:
            video = video.subclip(t_end=duration)


        audio_file = "content/static/sounds/" + slugify(f'{title}') + format

        video.audio.write_audiofile(audio_file)

        while tweak and not typer.confirm(f"Audio file saved to {audio_file}. Tweaking done?"):
            start_time = typer.prompt("Enter clip start time", default=start_time)
            duration = typer.prompt("Enter duration of the clip, in seconds", default=duration)
            video = original_video.subclip(t_start=start_time)
            if duration > 0:
                video = video.subclip(t_end=duration)

            video.audio.write_audiofile(audio_file)

        add_sound(title, file=audio_file, image=image)



@app.command("add")
def add_sound(
        title: str = typer.Option(..., prompt="Enter sound title"), 
        file: str = typer.Option(..., prompt="Enter sound file"),
        sounds_file: str = "content/index.json",
        image: str = None
    ):
    """Add an existing sound file to the list."""
    typer.echo(f"Adding sound {title} to the list...")
    sounds = load_sounds(sounds_file)

    sound = {
        "title": title,
        "id": str(uuid4()),
    }


    filename = slugify(title) + os.path.splitext(file)[1]
    try:
        shutil.copyfile(file, f"content/static/sounds/{filename}")
    except shutil.SameFileError:
        pass
    sound["sound"] = f"/static/sounds/{filename}"


    if image:
        typer.echo(f"Adding '{image}' as sound image")
        filename = slugify(title) + os.path.splitext(image)[1]
        try:
            shutil.copyfile(image, f"content/static/icons/{filename}")
        except shutil.SameFileError:
            pass
        sound["icon"] = f"/static/icons/{filename}"

    if sound["sound"] not in [s['sound'] for s in sounds]:
        sounds.append(sound)
        
    typer.echo(f"Adding sound: {sound}")

    save_sounds(sounds_file, sounds)
        

@app.command("convert")
def convert_audio_files(target: str = '.mp3', sounds_file: str = "content/index.json", delete: bool = True):
    sounds = load_sounds(sounds_file)

    for sound in sounds:
        with mp.AudioFileClip('content' + sound["sound"]) as audio:
            new_filename = ".".join(sound["sound"].split(".")[:-1]) + target
            typer.echo(f"Converting '{sound['sound']}' --> '{new_filename}'")
            audio.write_audiofile('content' + new_filename)
            os.unlink('content/' + sound["sound"])
            sound["sound"] = new_filename

    save_sounds(sounds_file, sounds)


@app.command("add-icons")
def find_icons_for_existing_sounds(folder: str = "content/static/icons", sounds_file: str = "content/index.json", extension: str = '.png'):
    sounds = load_sounds(sounds_file)

    for sound in sounds:
        if "icon" not in sound:
            filename = slugify(sound['title']) + extension
            test_path = os.path.join(folder, filename)
            if os.path.isfile(test_path):
                typer.echo(f"Adding '{test_path}' as sound image")
                try:
                    shutil.copyfile(test_path, f"content/static/icons/{filename}")
                except shutil.SameFileError:
                    pass

                sound["icon"] = f"/static/icons/{filename}"

    save_sounds(sounds_file, sounds)



if __name__ == "__main__":
    app()